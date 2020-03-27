use crate::db::Conn;
use crate::models::{{ table.name_singular }}::*;
use crate::schema::{{ table.name_plural }};
use std::ops::Deref;

use diesel::prelude::*;
use diesel::result::{DatabaseErrorKind, Error};
use serde::Deserialize;

#[derive(Insertable)]
#[table_name = "{{ table.name_plural }}"]
pub struct New{{ table.name_singular | title }} {
    {% for field in table.fields %}
        {% if field.key == "id" %}{% continue %}{% endif %}
        pub {{ field.key }}: {{ field | to_rust_datatype }},
    {% endfor %}
}

pub enum {{ table.name_singular | title }}CreationError {
    Duplicated{{ table.name_singular | title }}Name,
}

impl From<Error> for {{ table.name_singular | title }}CreationError {
    fn from(err: Error) -> {{ table.name_singular | title }}CreationError {
        if let Error::DatabaseError(DatabaseErrorKind::UniqueViolation, info) = &err {
            match info.constraint_name() {
                Some("{{ table.name_singular }}_name_key") => return {{ table.name_singular | title }}CreationError::Duplicated{{ table.name_singular | title }}Name,
                _ => {}
            }
        }
        panic!("Error creating {{ table.name_singular }}: {:?}", err)
    }
}

pub fn create(
    conn: &Conn,
    {% for field in table.fields %}
    {% if field.key == "id" %}{% continue %}{% endif %}
    {{ field.key }}: {{ field | to_rust_datatype }},
    {% endfor %}
) -> Result<{{ table.name_singular | title }}, {{ table.name_singular | title }}CreationError> {

    let new_{{ table.name_singular }} = &New{{ table.name_singular | title }} {
        {% for field in table.fields %}
           {% if field.key == "id" %}{% continue %}{% endif %}
           {{ field.key }},
        {% endfor %}
    };

    diesel::insert_into({{ table.name_plural }}::table)
        .values(new_{{ table.name_singular }})
        .get_result::<{{ table.name_singular | title }}>(conn.deref())
        .map_err(Into::into)
}


/// Return a list of all {{ table.name_plural | title }}
/// TODO: Pagination
pub fn find(conn: &Conn) -> Option<{{ table.name_singular | title }}List> {

    let {{ table.name_plural }} : Vec<{{ table.name_singular | title }}> = {{ table.name_plural }}::table.load::<{{ table.name_singular | title }}>(conn.deref())
        .map_err(|err| println!("Can not load {{ table.name_plural }}!: {}", err))
        .unwrap();

    Some({{ table.name_singular | title }}List{
        {{ table.name_plural }}
    })
}


pub fn find_one(conn: &Conn, id: i32) -> Option<{{ table.name_singular | title }}> {
    {{ table.name_plural }}::table
        .find(id)
        .get_result(conn.deref())
        .map_err(|err| println!("find_{{ table.name_singular }}: {}", err))
        .ok()
}

pub fn delete(conn: &Conn, id: i32) {
    let result = diesel::delete({{ table.name_plural }}::table.filter({{ table.name_plural }}::id.eq(id))).execute(conn.deref());
    if let Err(err) = result {
        eprintln!("{{ table.name_plural }}::delete: {}", err);
    }
}

// TODO: remove clone when diesel will allow skipping fields
#[derive(Deserialize, AsChangeset, Default, Clone)]
#[table_name = "{{ table.name_plural }}"]
pub struct Update{{ table.name_singular | title }}Data {
    {% for field in table.fields %}
    {% if field.key == "id" %}{% continue %}{% endif %}
    pub {{ field.key }}: {{ field | to_rust_datatype }},
    {% endfor %}
}

pub fn update(conn: &Conn, id: i32, data: &Update{{ table.name_singular | title }}Data) -> Option<{{ table.name_singular | title }}> {
    let data = &Update{{ table.name_singular | title }}Data {
        // Place to set particular fields... ex password: None,
        ..data.clone()
    };
    diesel::update({{ table.name_plural }}::table.find(id))
        .set(data)
        .get_result(conn.deref())
        .ok()
}
