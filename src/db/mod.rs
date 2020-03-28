use rocket_contrib::databases::diesel;

{% for table in tables -%}
pub mod {{table.name_plural}};
{% endfor -%}


{% if database_type == "sqlite" %}
{% set db_conn = "Sqlite" %}
{% set db_pck = "sqlite" %}
{% elif database_type == "postgres" %}
{% set db_conn = "Pg" %}
{% set db_pck = "pg" %}
{% else %}
{% set db_conn = "Pg" %}
{% set db_pck = "pg" %}
{% endif -%}


#[database("diesel_{{ database_type }}_pool")]
pub struct Conn(diesel::{{ db_conn }}Connection);


use diesel::{{ db_pck }}::{{ db_conn }};
use diesel::prelude::*;
use diesel::query_builder::*;
use diesel::query_dsl::methods::LoadQuery;
use diesel::sql_types::BigInt;

pub trait OffsetLimit: Sized {
    fn offset_and_limit(self, offset: i64, limit: i64) -> OffsetLimited<Self>;
}

impl<T> OffsetLimit for T {
    fn offset_and_limit(self, offset: i64, limit: i64) -> OffsetLimited<Self> {
        OffsetLimited {
            query: self,
            limit,
            offset,
        }
    }
}

#[derive(Debug, Clone, Copy, QueryId)]
pub struct OffsetLimited<T> {
    query: T,
    offset: i64,
    limit: i64,
}

impl<T> OffsetLimited<T> {
    #[allow(dead_code)]
    pub fn load_and_count<U>(self, conn: &{{ db_conn }}Connection) -> QueryResult<(Vec<U>, i64)>
    where
        Self: LoadQuery<{{ db_conn }}Connection, (U, i64)>,
    {
        let results = self.load::<(U, i64)>(conn)?;
        let total = results.get(0).map(|x| x.1).unwrap_or(0);
        let records = results.into_iter().map(|x| x.0).collect();
        Ok((records, total))
    }
}

impl<T: Query> Query for OffsetLimited<T> {
    type SqlType = (T::SqlType, BigInt);
}

impl<T> RunQueryDsl<{{ db_conn }}Connection> for OffsetLimited<T> {}

impl<T> QueryFragment<{{ db_conn }}> for OffsetLimited<T>
where
    T: QueryFragment<{{ db_conn }}>,
{
    fn walk_ast(&self, mut out: AstPass<{{ db_conn }}>) -> QueryResult<()> {
        out.push_sql("SELECT *, COUNT(*) OVER () FROM (");
        self.query.walk_ast(out.reborrow())?;
        out.push_sql(") t LIMIT ");
        out.push_bind_param::<BigInt, _>(&self.limit)?;
        out.push_sql(" OFFSET ");
        out.push_bind_param::<BigInt, _>(&self.offset)?;
        Ok(())
    }
}
