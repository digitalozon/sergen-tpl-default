#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use]
extern crate rocket;
#[macro_use]
extern crate rocket_contrib;
use rocket_cors;
#[macro_use]
extern crate diesel;
#[macro_use]
extern crate validator_derive;

mod auth;
mod db;
mod errors;
mod routes;
mod schema;
pub mod config;
pub mod models;


use dotenv;
use rocket_contrib::json::JsonValue;
use rocket_cors::Cors;

#[catch(404)]
fn not_found() -> JsonValue {
    json!({
        "status": "error",
        "reason": "Resource was not found."
    })
}

pub enum Environment {
    Dev,
    Test,
    Production,
}

fn cors_fairing() -> Cors {
    Cors::from_options(&Default::default()).expect("Cors fairing cannot be created")
}

pub fn load_env(env: Option<Environment>) {
    // Load proper .env file
    match env {
        Some(_) => dotenv::from_filename(".env.test").ok(),
        _ => dotenv::dotenv().ok(),
    };
}

pub fn rocket() -> rocket::Rocket {
    rocket::custom(config::from_env())
        .mount(
            "/api",
            routes![
                {%- for table in tables %}
                routes::{{table.name_plural}}::post_{{table.name_singular}},
                routes::{{table.name_plural}}::put_{{table.name_singular}},
                routes::{{table.name_plural}}::get_{{table.name_plural}},
                routes::{{table.name_plural}}::get_{{table.name_singular}},
                routes::{{table.name_plural}}::delete_{{table.name_singular}},
                {% endfor %}
            ], // TODO: POST list, PUT list, DELETE list
        )
        .attach(db::Conn::fairing())
        .attach(cors_fairing())
        .attach(config::AppState::manage())
        .register(catchers![not_found])
}
