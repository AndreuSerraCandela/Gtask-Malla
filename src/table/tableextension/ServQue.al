tableextension 92158 ServCue extends "Service Cue"
{
    fields
    {
        field(90038; "Tareas Pendientes"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("User Task" where(Estado = filter(<> Finalizado), Servicio = field("Filtro Servicio")));
        }
        field(90039; "Filtro Servicio"; Code[20])
        {
            FieldClass = FlowFilter;
        }
    }
}