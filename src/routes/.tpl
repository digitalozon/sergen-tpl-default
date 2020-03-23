use rocket::State;
use rocket_contrib::json::{Json, JsonValue};
use serde::Deserialize;
use validator::Validate;

use crate::auth::{ApiKey, Auth};
use crate::config::AppState;
use crate::db::{self, {{table}}::{{Table-singular}}CreationError};
use crate::errors::{Errors, FieldValidator};

#[derive(Deserialize)]
pub struct New{{Table-singular}} {
    {{table-singular}}: New{{Table-singular}}Data,
}

#[derive(Deserialize, Validate)]
struct New{{Table-singular}}Data {
    #[validate(length(min = 1))]
    name: Option<String>,
}

#[post("/{{table}}", format = "json", data = "<new_{{table-singular}}>")]
pub fn post_{{table-singular}}(
    new_{{table-singular}}: Json<New{{Table-singular}}>,
    conn: db::Conn,
    state: State<AppState>,
) -> Result<JsonValue, Errors> {
    let new_{{table-singular}} = new_{{table-singular}}.into_inner().{{table-singular}};

    let mut extractor = FieldValidator::validate(&new_{{table-singular}});
    let name = extractor.extract("name", new_{{table-singular}}.name);

    extractor.check()?;

    db::{{table}}::create(&conn, &name)
        .map(|{{table-singular}}| json!({ "{{table-singular}}": {{table-singular}}.before_insert() }))
        .map_err(|error| {
            let field = match error {
                {{Table-singular}}CreationError::Duplicated{{Table-singular}}Name => "name",
            };
            Errors::new(&[(field, "has already been taken")])
        })
}

#[get("/{{table}}")]
pub fn get_{{table}}(_key: ApiKey, conn: db::Conn) -> Option<JsonValue> {
    db::{{table}}::find(&conn).map(|{{table-singular}}| json!({{table-singular}}))
}

#[get("/{{table}}/<id>")]
pub fn get_{{table-singular}}(_key: ApiKey, id: i32, conn: db::Conn) -> Option<JsonValue> {
    db::{{table}}::find_one(&conn, id).map(|{{table-singular}}| json!({ "{{table-singular}}": {{table-singular}} }))
}

#[derive(Deserialize)]
pub struct Update{{Table-singular}} {
    {{table-singular}}: db::{{table}}::Update{{Table-singular}}Data,
}

#[put("/{{table}}", format = "json", data = "<{{table-singular}}>")]
pub fn put_{{table-singular}}(
    {{table-singular}}: Json<Update{{Table-singular}}>,
    auth: Auth,
    conn: db::Conn,
    state: State<AppState>,
) -> Option<JsonValue> {
    db::{{table}}::update(&conn, auth.id, &{{table-singular}}.{{table-singular}})
        .map(|{{table-singular}}| json!({ "{{table-singular}}": {{table-singular}}.before_insert() }))
}

#[delete("/{{table}}/<id>")]
pub fn delete_{{table-singular}}(id: i32, _auth: Auth, conn: db::Conn) {
    db::{{table}}::delete(&conn, id);
}
