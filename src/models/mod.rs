{% for table in tables %}
pub mod {{table.name_singilar}};
{% endfor %}