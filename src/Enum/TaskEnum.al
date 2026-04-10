enum 50020 "Task Enum"
{
    value(0; "Pendiente")
    {
        Caption = 'Pendiente';
    }
    value(1; "En Proceso")
    {
        Caption = 'En Proceso';
    }
    value(2; "Finalizado")
    {
        Caption = 'Finalizado';
    }
    value(3; "Cancelado")
    {
        Caption = 'Cancelado';
    }
}
enum 50021 "Tipo Incidencia"
{
    value(0; "Incidencias Mobiliario Urbano") { Caption = 'Mobiliario Urbano'; }
    value(1; "Incidencias EMT") { Caption = 'EMT'; }
    value(2; "Incidencias Soportes") { Caption = 'Soportes'; }
}
enum 50025 "SubTipo Incidencia"
{
    value(0; "Mantenimiento") { }
    value(1; "Limpieza") { }
    value(2; "Electrica") { }
    value(3; "Poda") { }
    value(4; "Tip") { }
    value(5; "Otras") { }
    //Limpieza,Electrica,Poda,Tip,Otras
}