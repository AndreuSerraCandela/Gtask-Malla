pageextension 92172 "TaskList" extends "Task List"
{

    actions
    {
        addafter("&Create Task")
        {
            action("Crear Tarea CMT")
            {
                Caption = 'Crear Tarea CMT';
                ApplicationArea = All;
                Image = TaskPage;
                trigger OnAction()
                var
                    Gtask: Codeunit GTask;
                    RecRef: RecordRef;
                    Resource: Record Resource;
                begin
                    Gtask.CrearCategorias(CompanyName);
                    Commit();
                    Message('Elija El recurso o dejar em blaco para nuevos');
                    If Page.RunModal(0, Resource) = Action::LookupOK then begin
                        RecRef.GetTable(Resource);
                        Gtask.CrearTarea(RecRef, 'Montaje del recurso ' + Resource.name + ' con el número ' + Resource."No." + ', ',
                        'COMERCIAL', 'MEDIOS', 'Montaje' + Resource.Name, 'TMC', false, '', '');
                    End else begin
                        RecRef.GetTable(Rec);
                        Gtask.CrearTarea(RecRef, 'Montaje nuevo recurso, ',
                        'COMERCIAL', 'MEDIOS', 'Montaje', 'TMC', false, '', '');
                    end;
                end;

            }
        }
    }
    trigger OnOpenPage()
    begin
        // Rec.SetRange("Assigned To", UserSecurityId());
    end;

    var
        EstadoStyle: Text;



}
