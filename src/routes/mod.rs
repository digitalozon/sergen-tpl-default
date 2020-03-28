{% for table in tables -%}
pub mod {{table.name_plural}};
{% endfor %}
