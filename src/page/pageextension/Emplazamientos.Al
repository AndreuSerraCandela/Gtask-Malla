pageextension 92156 EmplazaExt extends "Ficha emplazamiento"
{
    actions
    {
        addafter("New Mail Message")
        {
            group("Tareas Firma Emplazamiento")
            {
                Image = TaskQualityMeasure;

                action("PRE-MONTAJE")
                {
                    ApplicationArea = All;
                    Image = TaskPage;
                    trigger OnAction()
                    var
                        Gtask: Codeunit GTask;

                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        Gtask.CrearTarea(RecRef, Rec."Descripción", 'TECNICO', 'TECNICO', Rec."Descripción", 'PRE-MONTAJE', false, '', '');


                    end;
                }
                action("Tarea Solicitud Emplazamiento PRE-Pnel")
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
                        Gtask.CrearTarea(RecRef, 'Sería posible obtener permiso para ' + Rec."Descripción" + ' con el número ' + Rec."Nº Emplazamiento" + ', sito en la calle ' + Rec.Calle,
                        'JURIDICO', 'TECNICO', 'Pre-Solicitud permiso ' + Rec."Descripción", 'Solicitud', false, '', '');


                    end;
                }
                action("Comunicar Pnl a Jurídico")
                {
                    ApplicationArea = All;
                    Image = TaskPage;
                    trigger OnAction()
                    var
                        Gtask: Codeunit GTask;

                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        Gtask.CrearTarea(RecRef, 'Pnel Emplazamiento ' + Rec."Nº Emplazamiento", 'JURIDICO', 'TECNICO', 'Pnel Emplazamiento ' + Rec."Nº Emplazamiento", 'PNEL', false, '', '');
                    end;
                }

                action("Crear Tarea Emplazamiento")
                {
                    ApplicationArea = All;
                    Image = ViewJob;
                    trigger OnAction()
                    var
                        Gtask: Codeunit GTask;
                        UsuariodGtask: Record UsuariosGtask;
                        Supervisor: Guid;
                        Responsable: Guid;
                        RecRef: RecordRef;
                    begin
                        Gtask.CrearCategorias(CompanyName);
                        Commit();
                        RecRef.GetTable(Rec);
                        UsuariodGtask.ChangeCompany('Malla Publicidad');
                        UsuariodGtask.SetRange(Departamento, 'TECNICO');
                        UsuariodGtask.SetRange(Supervisor, true);
                        if UsuariodGtask.FindFirst() then
                            Supervisor := UsuariodGtask."Id Usuario";
                        if not IsNullGuid(Supervisor) then begin
                            UsuariodGtask.SetRange(Supervisor);
                            UsuariodGtask.SetFilter("Id Usuario", '<>%1', Supervisor);
                            if UsuariodGtask.FindFirst() then
                                Responsable := UsuariodGtask."Id Usuario";
                        end;
                        if IsNullGuid(Responsable) then
                            Responsable := Supervisor;

                        Gtask.CrearTareaEmpazamiento(RecRef, Rec."Nº Emplazamiento" + ' ' + Rec."Descripción"
                        , Responsable, Supervisor, 'TECNICO', 'TECNICO', false, '');


                    end;
                }

            }
            group("TareasMontaje/Desmontaje Emplazamiento")
            {
                Image = TaskQualityMeasure;
                group(Tecnico)
                {
                    group(Montaje)
                    {
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
                                Gtask.CrearTarea(RecRef, 'Emplazamiento ' + Rec."Nº Emplazamiento" + ' proceder al montaje de los recuros ',
                                'MEDIOS', 'TECNICO', 'Crear recursos emplazamiento ' + Rec."Descripción", 'ALTA RECURSOS', false, '', '');


                            end;
                        }
                        action("Crear Orden Pre-Montaje Taller")
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
                                Gtask.CrearTarea(RecRef, 'Visita conjunta al emplazamiento ' + Rec."Nº Emplazamiento",
                                'TALLER', 'TECNICO', 'Pre-Montaje emplazamiento ' + Rec."Descripción", 'Montaje', false, '', '');


                            end;
                        }
                        action("Crear Orden Montaje Taller")
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
                                Gtask.CrearTarea(RecRef, 'Proceder al montaje de los recuros ' + ListaRecursos + ' del emplazamiento ' + Rec."Nº Emplazamiento",
                                'TALLER', 'TECNICO', 'Montaje recursos emplazamiento ' + Rec."Descripción", 'Montaje', false, '', '');


                            end;
                        }
                    }
                    group(Desmontaje)
                    {
                        action("Crear Tarea TMC Tecnico")
                        {
                            Caption = 'Crear Tarea TMC-Fijar en Blanco';
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
                                Message('Elija El recurso');
                                Resource.SetRange("Nº Emplazamiento", Rec."Nº Emplazamiento");
                                If Page.RunModal(0, Resource) = Action::LookupOK then begin
                                    RecRef.GetTable(Resource);
                                    Gtask.CrearTarea(RecRef, 'Fijar en blanco el recurso ' + Resource.name + ' con el número ' + Resource."No." + ', si está en algún contrato, se debe desvincular e informar al cliente y al comercial',
                                    'MEDIOS', 'TECNICO', 'Medidas Cautelares ' + Resource.Name, 'TMC', false, '', '');
                                End;

                            end;
                        }
                        action("Crear Tarea Desmontaje Tec")
                        {
                            Caption = 'Crear Tarea Desmontaje';
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
                                Message('Elija El recurso');
                                Resource.SetRange("Nº Emplazamiento", Rec."Nº Emplazamiento");
                                If Page.RunModal(0, Resource) = Action::LookupOK then begin
                                    RecRef.GetTable(Resource);
                                    Gtask.CrearTarea(RecRef, 'Proceder a desmontar ' + Resource.name + ' con el número ' + Resource."No.",
                                    'TALLER', 'TECNICO', 'Desmontar recurso ' + Resource.Name, 'DESMONTAJE', false, '', '');
                                end;

                            end;
                        }
                    }
                }
                group(Medios)
                {

                    action("Crear Tarea TMC Medios")
                    {
                        Caption = 'Crear Tarea TMC-Fijar Blanco';
                        ApplicationArea = All;
                        Image = TaskPage;
                        trigger OnAction()
                        var
                            Gtask: Codeunit GTask;
                            RecRef: RecordRef;
                            Tipos: Record "Tipo Recurso";
                            Fichero: Text;
                            Adjuntar: Boolean;
                            Resource: Record Resource;
                        begin
                            Gtask.CrearCategorias(CompanyName);
                            Commit();
                            Message('Elija El recurso');
                            Resource.SetRange("Nº Emplazamiento", Rec."Nº Emplazamiento");
                            If Page.RunModal(0, Resource) = Action::LookupOK then begin
                                RecRef.GetTable(Resource);
                                If Not Tipos.Get(Resource."Tipo Recurso") then
                                    Tipos.Init();
                                Fichero := Tipos."Ruta imagenes" + '\' + Resource."No.";
                                //Adjuntar := Exists(Fichero);
                                Adjuntar := true;
                                If Not Adjuntar then
                                    Fichero := '';
                                Gtask.CrearTarea(RecRef, 'Fijar en blanco el recurso ' + Resource.name + ' con el número ' + Resource."No." + ', si está en algún contrato, se debe desvincular e informar al cliente y al comercial',
                                'TALLER', 'MEDIOS', 'Fijacion en blanco ' + Resource.Name, 'TMC', Adjuntar, Fichero, '.pdf');

                                // RecRef.Close();
                                // Clear(RecRef);
                                // RecRef.GetTable(Usertask);
                                // RecRef.Get(Usertask.RecordId);
                                // TM.Insert();
                                // tm.CalcFields(Content);
                                // Tm.Content.CreateInStream(InStr);
                                // DoccAttach.SaveAttachmentFromStream(InStr, RecRef, Rec."No." + '.pdf');
                                // //DoccAttach.Insert();
                                // tm.Delete();
                                // Clear(Gtask);
                                // Gtask.CrearTareaTecnico(Rec."No.", UserTask, UserTask.Departamento, UserTask.Servicio, true);
                                // Gtask.Email(UserTask, EmailResponsable, EmailSupervisor);
                                // EnviaCorreo(Usertask, true, '', false, 'TMC ' + Rec."No.", EmailResponsable, EmailSupervisor, '', User."Full Name");
                            end;
                        end;
                    }
                }
                group(Juridico)
                {
                    action("Crear Tarea TMC- Medidas Cautelares")
                    {
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
                            Message('Elija El recurso');
                            Resource.SetRange("Nº Emplazamiento", Rec."Nº Emplazamiento");
                            If Page.RunModal(0, Resource) = Action::LookupOK then begin
                                RecRef.GetTable(Resource);
                                Gtask.CrearTarea(RecRef, 'Inicio medidas cautelares ' + Resource.name + ' con el número ' + Resource."No.",
                                'TECNICO', 'JURIDICO', 'Medidas Cautelares ' + Resource.Name, 'TMC', false, '', '');
                            End;

                        end;
                    }
                    action("Crear Tarea Desmontaje")
                    {
                        ApplicationArea = All;
                        Image = TaskPage;
                        trigger OnAction()
                        var
                            Gtask: Codeunit GTask;
                            RecRef: RecordRef;
                            Resource: Record Resource;
                        begin
                            Message('Elija El recurso a desmontar');
                            Resource.SetRange("Nº Emplazamiento", Rec."Nº Emplazamiento");
                            If Page.RunModal(0, Resource) = Action::LookupOK then begin
                                Gtask.CrearCategorias(CompanyName);
                                Commit();
                                RecRef.GetTable(Resource);
                                Gtask.CrearTarea(RecRef, 'Proceder a desmontar ' + Resource.name + ' con el número ' + Resource."No.",
                                'TECNICO', 'JURIDICO', 'Desmontar recurso ' + Resource.Name, 'DESMONTAJE', false, '', '');
                            End;
                        end;
                    }
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
                    Usertask.SetRange(Id_Record, Rec.RecordId);
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