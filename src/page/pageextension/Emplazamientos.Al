pageextension 92156 EmplazaExt extends "Ficha emplazamiento"
{
    actions
    {
        addafter("New Mail Message")
        {
            group("Tareas Técnio")
            {
                Image = TaskQualityMeasure;

                action("Crear Tareas Emplazamiento")
                {
                    ApplicationArea = All;
                    Image = TaskPage;
                    trigger OnAction()
                    var
                        Gtask: Codeunit GTask;

                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        Gtask.CrearTarea(RecRef, Rec."Descripción", 'TECNICO', 'TECNICO', Rec."Descripción", '', false, '');


                    end;
                }
                action("Crear Tarea Solicitud Emplazamiento")
                {
                    ApplicationArea = All;
                    Image = ViewJob;
                    trigger OnAction()
                    var
                        Gtask: Codeunit GTask;
                        RecRef: RecordRef;
                    begin
                        Gtask.CrearCategorias(CompanyName);
                        Commit();
                        RecRef.GetTable(Rec);
                        Gtask.CrearTarea(RecRef, 'Iniciar solicitud para el emplazamiento ' + Rec."Descripción" + ' con el número ' + Rec."Nº Emplazamiento",
                        'JURIDICO', 'TECNICO', 'Solicitud permiso ' + Rec."Descripción", 'Solicitud', false, '');


                    end;
                }
                action("Crear Tarea Alta Recursos Medios")
                {
                    ApplicationArea = All;
                    Image = ResourceGroup;
                    trigger OnAction()
                    var
                        Gtask: Codeunit GTask;
                        RecRef: RecordRef;
                        Recursos: Record Resource;
                        ListaRecursos: Text;
                    begin
                        Gtask.CrearCategorias(CompanyName);
                        Commit();
                        Recursos.SetRange("Nº Emplazamiento", Rec."Nº Emplazamiento");
                        if Recursos.FindSet() then
                            repeat
                                ListaRecursos := ListaRecursos + Recursos."No." + ', ';
                            until Recursos.Next() = 0;
                        if ListaRecursos <> '' then
                            ListaRecursos := CopyStr(ListaRecursos, 1, StrLen(ListaRecursos) - 2);
                        RecRef.GetTable(Rec);
                        Gtask.CrearTarea(RecRef, 'Proceder al monjage de los recuros ' + ListaRecursos + ' del emplazamiento ' + Rec."Nº Emplazamiento",
                        'MEDIOS', 'TECNICO', 'Crear recursos emplazamienyo ' + Rec."Descripción", 'Montaje', false, '');


                    end;
                }
                action("Crear Tarea Alta Recursos Taller")
                {
                    ApplicationArea = All;
                    Image = WorkTax;
                    trigger OnAction()
                    var
                        Gtask: Codeunit GTask;
                        RecRef: RecordRef;
                        Recursos: Record Resource;
                        ListaRecursos: Text;
                    begin
                        Gtask.CrearCategorias(CompanyName);
                        Commit();
                        Recursos.SetRange("Nº Emplazamiento", Rec."Nº Emplazamiento");
                        if Recursos.FindSet() then
                            repeat
                                ListaRecursos := ListaRecursos + Recursos."No." + ', ';
                            until Recursos.Next() = 0;
                        if ListaRecursos <> '' then
                            ListaRecursos := CopyStr(ListaRecursos, 1, StrLen(ListaRecursos) - 2);
                        RecRef.GetTable(Rec);
                        Gtask.CrearTarea(RecRef, 'Proceder al monjage de los recuros ' + ListaRecursos + ' del emplazamiento ' + Rec."Nº Emplazamiento",
                        'TALLER', 'TECNICO', 'Crear recursos emplazamienyo ' + Rec."Descripción", 'Montaje', false, '');


                    end;
                }
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
                    Usertask.SetRange("No.", Rec."Nº Emplazamiento");
                    If Not Usertask.FindFirst() then
                        Error('No existe una tarea para esta emplazamiento')
                    else
                        Page.RunModal(0, Usertask);

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