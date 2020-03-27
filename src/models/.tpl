use serde::Serialize;

#[derive(Queryable, Serialize)]
pub struct {{ table.name_singular | title }} {
    {% for field in table.fields %}
        pub {{ field.key }}: {{ field | to_rust_datatype }},
    {% endfor %}
}

#[derive(Queryable, Serialize)]
pub struct {{ table.name_singular | title }}List {
    pub {{ table.name_plural}}: Vec<{{ table.name_singular | title }}>,
}


impl {{ table.name_singular | title }} {
  pub fn before_insert(&self) -> &{{ table.name_singular | title }} {
     // TODO:
     self
   }
}

