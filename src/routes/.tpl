use rocket::State;
use rocket_contrib::json::{Json, JsonValue};
use serde::Deserialize;
use validator::Validate;

use crate::auth::{ApiKey, Auth};
use crate::config::AppState;
use crate::db::{self, {{ table.name_plural }}::{{ table.name_singular | title }}CreationError};
use crate::errors::{Errors, FieldValidator};

#[derive(Deserialize)]
pub struct New{{ table.name_singular | title }} {
    {{ table.name_singular }}: New{{ table.name_singular | title }}Data,
}

#[derive(Deserialize, Validate)]
struct New{{ table.name_singular | title }}Data {
    {% for field in table.fields %} {% if field.key == "id" %}{% continue %}{% endif -%}
        pub {{ field.key }}: {{ field | to_rust_datatype }},
    {% endfor %}
}

#[post("/{{ table.name_plural }}", format = "json", data = "<new_{{ table.name_singular }}>")]
pub fn post_{{ table.name_singular }}(
    new_{{ table.name_singular }}: Json<New{{ table.name_singular | title }}>,
    conn: db::Conn,
    _state: State<AppState>,
) -> Result<JsonValue, Errors> {
    let new_{{ table.name_singular }} = new_{{ table.name_singular }}.into_inner().{{ table.name_singular }};

    let extractor = FieldValidator::validate(&new_{{ table.name_singular }});

    // Prepare all fields for inserting (validation)
    {% for field in table.fields %}{% if field.key == "id" %}{% continue %}{% endif %}
        {% if field.required | to_bool -%}
            let {{ field.key }} = new_{{ table.name_singular }}.{{ field.key }};
        {% else -%}
            let {{ field.key }} = extractor.extract("{{ field.key }}", new_{{ table.name_singular }}.{{ field.key }});
        {% endif %}
    {%- endfor %}

    extractor.check()?;

    db::{{ table.name_plural }}::create(&conn {% for field in table.fields %} {% if field.key == "id" %}{% continue %}{% endif %} , {{ field.key }} {% endfor %})
        .map(|{{ table.name_singular }}| json!({ "{{ table.name_singular }}": {{ table.name_singular }}.before_insert() }))
        .map_err(|error| {
            let field = match error {
                // TODO: "name"?
                {{ table.name_singular | title }}CreationError::Duplicated{{ table.name_singular | title }}Name => "name",
            };
            Errors::new(&[(field, "has already been taken")])
        })
}

#[get("/{{ table.name_plural }}")]
pub fn get_{{ table.name_plural }}(_key: ApiKey, conn: db::Conn) -> Option<JsonValue> {
    db::{{ table.name_plural }}::find(&conn).map(|{{ table.name_singular }}| json!({{ table.name_singular }}))
}

#[get("/{{ table.name_plural }}/<id>")]
pub fn get_{{ table.name_singular }}(_key: ApiKey, id: i32, conn: db::Conn) -> Option<JsonValue> {
    db::{{ table.name_plural }}::find_one(&conn, id).map(|{{ table.name_singular }}| json!({ "{{ table.name_singular }}": {{ table.name_singular }} }))
}

#[derive(Deserialize)]
pub struct Update{{ table.name_singular | title }} {
    {{ table.name_singular }}: db::{{ table.name_plural }}::Update{{ table.name_singular | title }}Data,
}

#[put("/{{ table.name_plural }}", format = "json", data = "<{{ table.name_singular }}>")]
pub fn put_{{ table.name_singular }}(
    {{ table.name_singular }}: Json<Update{{ table.name_singular | title }}>,
    auth: Auth,
    conn: db::Conn,
    _state: State<AppState>,
) -> Option<JsonValue> {
    db::{{ table.name_plural }}::update(&conn, auth.id, &{{ table.name_singular }}.{{ table.name_singular }})
        .map(|{{ table.name_singular }}| json!({ "{{ table.name_singular }}": {{ table.name_singular }}.before_insert() }))
}

#[delete("/{{ table.name_plural }}/<id>")]
pub fn delete_{{ table.name_singular }}(id: i32, _auth: Auth, conn: db::Conn) {
    db::{{ table.name_plural }}::delete(&conn, id);
}
