{% for table in tables %}
pub mod {{table.name_singular}};
{% endfor %}