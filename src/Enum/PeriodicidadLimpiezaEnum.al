enum 50022 "Tipo Periodicidad Limpieza"
{
    Caption = 'Tipo periodicidad';
    value(0; "Día semanal")
    {
        Caption = 'Día semanal (ej. todos los lunes)';
    }
    value(1; "Día del mes")
    {
        Caption = 'Día del mes (ej. día 1 y 15)';
    }
}

enum 50024 "Temporada Limpieza"
{
    Caption = 'Temporada';
    value(0; Todas)
    {
        Caption = 'Todas';
    }
    value(1; Verano)
    {
        Caption = 'Verano';
    }
    value(2; Invierno)
    {
        Caption = 'Invierno';
    }
}

enum 50023 "Día Semana Limpieza"
{
    Caption = 'Día de la semana';
    value(0; Ninguno)
    {
        Caption = ' ';
    }
    value(1; Lunes)
    {
        Caption = 'Lunes';
    }
    value(2; Martes)
    {
        Caption = 'Martes';
    }
    value(3; Miércoles)
    {
        Caption = 'Miércoles';
    }
    value(4; Jueves)
    {
        Caption = 'Jueves';
    }
    value(5; Viernes)
    {
        Caption = 'Viernes';
    }
}
