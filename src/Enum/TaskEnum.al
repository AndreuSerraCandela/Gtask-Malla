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
    value(0; "Incidencias Taller") { }
    value(1; "Incidencias EMT")
    { }
    value(2; "Incidencias Villena") { }
    //EMT,Mobiliario Urbano,Grupo Taller,Poda
    value(3; "Incidencias Mobiliario Urbano") { }
    value(4; "Incidencias Grupo Taller") { }
    value(5; "Incidencias Poda") { }
}