page 50127 "Detalle Log Parada"
{
    ApplicationArea = All;
    Caption = 'Detalle log parada';
    PageType = List;
    SourceTable = "User Task";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lineas)
            {
                field(Tipo; TipoEntradaTxt())
                {
                    ApplicationArea = All;
                    Caption = 'Tipo';
                    ToolTip = 'Incidencia, orden de trabajo o tarea.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        AbrirOrigen();
                    end;
                }
                field("Start DateTime"; Rec."Start DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'Fecha';
                    ToolTip = 'Fecha de la incidencia o tarea.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        AbrirOrigen();
                    end;
                }
                field("Due DateTime"; Rec."Due DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'Fecha vencimiento';
                    ToolTip = 'Fecha de vencimiento o actuación prevista.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        AbrirOrigen();
                    end;
                }
                field(Estado; Rec.Estado)
                {
                    ApplicationArea = All;
                    Caption = 'Estado';
                    ToolTip = 'Estado de la incidencia o tarea.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        AbrirOrigen();
                    end;
                }
                field(Title; Rec.Title)
                {
                    ApplicationArea = All;
                    Caption = 'Referencia';
                    ToolTip = 'Número o título de referencia.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        AbrirOrigen();
                    end;
                }
                field(Descripcion; Rec.GetDescription())
                {
                    ApplicationArea = All;
                    Caption = 'Descripción';
                    ToolTip = 'Descripción ampliada.';
                    MultiLine = true;
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        AbrirOrigen();
                    end;
                }
                field(Usuario; NombreUsuarioTxt())
                {
                    ApplicationArea = All;
                    Caption = 'Usuario';
                    ToolTip = 'Usuario asignado o creador.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    begin
                        AbrirOrigen();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AbrirRegistro)
            {
                ApplicationArea = All;
                Caption = 'Abrir';
                Image = View;
                ToolTip = 'Abre la incidencia, orden de trabajo o tarea asociada.';

                trigger OnAction()
                begin
                    AbrirOrigen();
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Actualizar';
                Image = Refresh;
                ToolTip = 'Vuelve a cargar incidencias y tareas de la parada.';

                trigger OnAction()
                var
                    Procesos_GTask: Codeunit Procesos_GTask;
                begin
                    Procesos_GTask.CargarLineas(Rec, EmplazamientoParada);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(AbrirRegistro_Promoted; AbrirRegistro) { }
                actionref(Refresh_Promoted; Refresh) { }
            }
        }
    }

    procedure SetEmplazamiento(Emplazamiento: Record Emplazamientos)
    begin
        EmplazamientoParada := Emplazamiento;
        EmplazamientoCargado := Emplazamiento."Nº Emplazamiento" <> '';
    end;

    trigger OnOpenPage()
    var
        Procesos_GTask: Codeunit Procesos_GTask;
    begin
        if not EmplazamientoCargado then
            Error('No se ha indicado la parada. Abra el detalle desde la ficha de la parada.');
        Procesos_GTask.CargarLineas(Rec, EmplazamientoParada);
    end;

    local procedure AbrirOrigen()
    var
        Procesos_GTask: Codeunit Procesos_GTask;
    begin
        Procesos_GTask.AbrirRegistroOrigen(Rec);
    end;

    local procedure TipoEntradaTxt(): Text[30]
    begin
        case Rec.Resource of
            'INCIDENCIA':
                exit('Incidencia');
            'ORDEN':
                exit('Orden trabajo');
            'TAREA':
                exit('Tarea');
            else
                if Rec.Id_record.TableNo = Database::Incidencias then
                    exit('Incidencia')
                else
                    exit('Tarea');
        end;
    end;

    local procedure NombreUsuarioTxt(): Text[100]
    var
        UsuarioGtask: Record UsuariosGtask;
    begin
        if IsNullGuid(Rec."Assigned To") then
            exit('');
        UsuarioGtask.SetRange("Id Usuario", Rec."Assigned To");
        if UsuarioGtask.FindFirst() then
            exit(CopyStr(UsuarioGtask.Nombre + ' ' + UsuarioGtask.Apellido, 1, 100));
        exit('');
    end;

    var
        EmplazamientoParada: Record Emplazamientos;
        EmplazamientoCargado: Boolean;
}
