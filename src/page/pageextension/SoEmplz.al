pageextension 92171 EmplazaActExt extends "Service Dispatcher Activities"
{
    layout
    {
        addafter(Visitas)
        {
            cuegroup(Tareas)
            {
                field("Tareas Pendientes"; Rec."Tareas Pendientes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Especifica el numero de tareas pendientes';
                    DrillDownPageId = "User Task List";
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    var
        UserGtask: Record UsuariosGtask;
    begin
        UserGtask.SetRange("Id Usuario", UserSecurityId());
        if UserGtask.FindFirst() then
            Rec.SetRange("Filtro Servicio", UserGtask.Departamento);
    end;

    trigger OnOpenPage()
    var
        UserGtask: Record UsuariosGtask;
    begin
        UserGtask.SetRange("Id Usuario", UserSecurityId());
        if UserGtask.FindFirst() then
            Rec.SetRange("Filtro Servicio", UserGtask.Departamento);
    end;
}