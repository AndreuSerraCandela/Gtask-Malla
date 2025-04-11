pageextension 92164 PnlExt extends "PNEL Emplazamientos"
{
    actions
    {

        addlast(Processing)
        {

            action("Comunicar a Jurídico")
            {
                ApplicationArea = All;
                Image = TaskPage;
                trigger OnAction()
                var
                    Gtask: Codeunit GTask;

                    RecRef: RecordRef;
                begin
                    RecRef.GetTable(Rec);
                    Gtask.CrearTarea(RecRef, 'Pnel Emplazamiento ' + Rec."Nº Emplazamiento", 'JURIDICO', 'TECNICO', 'Pnel Emplazamiento ' + Rec."Nº Emplazamiento", 'PNEL', false, '');
                end;
            }

            action("Ver Tareas")
            {
                Image = "TaskList";
                ApplicationArea = All;
                Caption = 'Ver Tareas';
                trigger OnAction()
                var

                    Usertask: Record "User Task";

                begin
                    Usertask.SetRange(Id_Record, Rec.RecordId);
                    Usertask.SetRange("User Task Group Assigned To", 'PNEL');
                    If Not Usertask.FindFirst() then
                        Error('No existe una tarea para esta emplazamiento')
                    else
                        Page.RunModal(1170, Usertask);

                end;
            }

        }
        //     addafter(AsignarImagenaLineas)
        //   {
        //     actionref(CreartareaRef;"Crear Tarea"){}
        //     actionref(VertareaRef;"Ver Tarea"){}
        //   }  
    }
    var
        Responsable: Guid;
        Supervisor: Guid;
}