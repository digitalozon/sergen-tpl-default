use crate::db::Conn;
use crate::models::{{table-singular}}::*;
use crate::schema::{{table}};
use std::ops::Deref;

use crypto::scrypt::{scrypt_check, scrypt_simple, ScryptParams};
use diesel::prelude::*;
use diesel::result::{DatabaseErrorKind, Error};
use serde::Deserialize;

#[derive(Insertable)]
#[table_name = "{{table}}"]
pub struct New{{Table-singular}}<'a> {
{{insertable-tbl-fields-def}}
}

pub enum {{Table-singular}}CreationError {
    Duplicated{{Table-singular}}Name,
}

impl From<Error> for {{Table-singular}}CreationError {
    fn from(err: Error) -> {{Table-singular}}CreationError {
        if let Error::DatabaseError(DatabaseErrorKind::UniqueViolation, info) = &err {
            match info.constraint_name() {
                Some("{{table-singular}}_name_key") => return {{Table-singular}}CreationError::Duplicated{{Table-singular}}Name,
                _ => {}
            }
        }
        panic!("Error creating {{table-singular}}: {:?}", err)
    }
}

pub fn create(
    conn: &Conn,
    {{insertable-tbl-fields-with-datatypes}}
) -> Result<{{Table-singular}}, {{Table-singular}}CreationError> {

    let new_{{table-singular}} = &New{{Table-singular}} {
    {{insertable-tbl-fields}}
    };

    diesel::insert_into({{table}}::table)
        .values(new_{{table-singular}})
        .get_result::<{{Table-singular}}>(conn.deref())
        .map_err(Into::into)
}


/// Return a list of all {{Table}}
/// TODO: Pagination
pub fn find(conn: &Conn) -> Option<{{Table-singular}}List> {

    let {{table}} : Vec<{{Table-singular}}> = {{table}}::table.load::<{{Table-singular}}>(conn.deref())
        .map_err(|err| println!("Can not load {{table}}!: {}", err))
        .unwrap();

    Some({{Table-singular}}List{
        {{table}}
    })
}


pub fn find_one(conn: &Conn, id: i32) -> Option<{{Table-singular}}> {
    {{table}}::table
        .find(id)
        .get_result(conn.deref())
        .map_err(|err| println!("find_{{table-singular}}: {}", err))
        .ok()
}

pub fn delete(conn: &Conn, id: i32) {
    let result = diesel::delete({{table}}::table.filter({{table}}::id.eq(id))).execute(conn.deref());
    if let Err(err) = result {
        eprintln!("{{table}}::delete: {}", err);
    }
}

// TODO: remove clone when diesel will allow skipping fields
#[derive(Deserialize, AsChangeset, Default, Clone)]
#[table_name = "{{table}}"]
pub struct Update{{Table-singular}}Data {
    name: Option<String>,
}

pub fn update(conn: &Conn, id: i32, data: &Update{{Table-singular}}Data) -> Option<{{Table-singular}}> {
    let data = &Update{{Table-singular}}Data {
        // Place to set particular fields... ex password: None,
        ..data.clone()
    };
    diesel::update({{table}}::table.find(id))
        .set(data)
        .get_result(conn.deref())
        .ok()
}
