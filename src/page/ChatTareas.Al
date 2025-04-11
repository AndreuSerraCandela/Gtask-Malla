page 50104 "Chat Tareas"
{
    PageType = List;// Worksheet;
    SourceTable = "To-do";
    UsageCategory = Lists;
    ApplicationArea = All;
    InsertAllowed = true;
    CardPageId = 5098;
    layout
    {
        area(content)
        {
            repeater(ToDo)
            {
                //añadir campos de la tarea
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(Tarea; ProcedureTarea(Rec.Id_Tabla, 'Descripcion'))
                {
                    ApplicationArea = All;


                }
                field("Descripción Emplazamiento"; ProcedureTarea(Rec.Id_Tabla, 'Descripcion Emplazamiento'))

                {
                    ApplicationArea = All;

                }

                field("Description"; Rec."Descripción Visita")
                {
                    Caption = 'Descripción';
                    ApplicationArea = All;
                }

                field(Responsable; ProcedureTarea(Rec.Id_Tabla, 'Responsable'))
                {
                    ApplicationArea = All;
                }
                field(Supervisor; ProcedureTarea(Rec.Id_Tabla, 'Supervisor'))
                {
                    ApplicationArea = All;
                }
                field("Fecha"; Rec."Date")
                {
                    ApplicationArea = All;
                }



                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    Caption = 'TECNICO';
                    ApplicationArea = All;
                }



            }
        }
        area(factboxes)
        {
            part(Adjuntos; "Document Attachment Factbox")
            {
                ApplicationArea = All;
                SubPageLink = "Table ID" = const(Database::"To-do"),
                            "No." = FIELD("No.");
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = true;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }





    actions
    {
        area(navigation)
        {
            group(Task)
            {
                Caption = 'Chat';
                Image = Task;
                action("Co&mment")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mentarios';
                    Image = ViewComments;
                    RunObject = Page "Rlshp. Mgt. Comment Sheet";
                    RunPageLink = "Table Name" = CONST("To-do"),
                                  "No." = FIELD("Organizer To-do No."),
                                  "Sub No." = CONST(0);
                    ToolTip = 'View or add comments.';
                }
                action("Interaction Log E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = '&Movimientos interacción';
                    Image = InteractionLog;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "To-do No." = FIELD("Organizer To-do No.");
                    RunPageView = SORTING("To-do No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View interaction log entries for the task.';
                }
                action("Postponed &Interactions")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = '&Interaciones aplazadas';
                    Image = PostponedInteractions;
                    RunObject = Page "Postponed Interactions";
                    RunPageLink = "To-do No." = FIELD("Organizer To-do No.");
                    RunPageView = SORTING("To-do No.");
                    ToolTip = 'View postponed interactions for the task.';
                }
                action("A&ttendee Scheduling")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Programar asistentes';
                    Image = ProfileCalender;
                    ToolTip = 'View the status of a scheduled meeting.';

                    trigger OnAction()
                    var
                        Task: Record "To-do";
                    begin
                        Task.Get(Rec."Organizer To-do No.");
                        PAGE.RunModal(PAGE::"Attendee Scheduling", Task);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unciones';
                Image = "Action";
                action("Assign Activities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Asignar Actividades';
                    Image = Allocate;
                    ToolTip = 'View all the tasks that have been assigned to salespeople and teams. A task can be organizing meetings, making phone calls, and so on.';

                    trigger OnAction()
                    var
                        TempTask: Record "To-do" temporary;
                    begin
                        TempTask.AssignActivityFromTask(Rec);
                    end;
                }
                // action(MakePhoneCall)
                // {
                //     ApplicationArea = RelationshipMgmt;
                //     Caption = 'Hacer una llamada';
                //     Image = Calls;
                //     ToolTip = 'Call the selected contact.';

                //     trigger OnAction()
                //     var
                //         TempSegmentLine: Record "Segment Line" temporary;
                //         ContactNo: Code[10];
                //         ContCompanyNo: Code[10];
                //     begin
                //         if Rec."Contact No." <> '' then
                //             ContactNo := Rec."Contact No."
                //         else
                //             ContactNo := Rec.GetFilter("Contact No.");
                //         if Rec."Contact Company No." <> '' then
                //             ContCompanyNo := Rec."Contact Company No."
                //         else
                //             ContCompanyNo := Rec.GetFilter("Contact Company No.");
                //         if ContactNo = '' then begin
                //             if (Rec.Type = Rec.Type::Meeting) and (Rec."Team Code" = '') then
                //                 Error(Text004);
                //             Error(Text005);
                //         end;
                //         TempSegmentLine."To-do No." := Rec."No.";
                //         TempSegmentLine."Contact No." := ContactNo;
                //         TempSegmentLine."Contact Company No." := ContCompanyNo;
                //         TempSegmentLine."Campaign No." := Rec."Campaign No.";
                //         TempSegmentLine."Salesperson Code" := Rec."Salesperson Code";
                //         TempSegmentLine.CreatePhoneCall();
                //     end;
                // }
                action("Delete Canceled Tasks")
                {
                    ApplicationArea = All;
                    Caption = 'Borrar &chats cancelados';
                    Image = Delete;
                    RunObject = Report "Delete Tasks";
                    ToolTip = 'Find and delete canceled tasks.';
                }
            }
            action("Solicitar Disponibilidad")
            {
                ApplicationArea = All;
                Caption = 'Solicitar Disponibilidad';
                Image = SendAsPDF;
                ToolTip = 'Solicitar Disponibilidad';
                trigger OnAction()
                begin
                    SolicitarDisponibilidad();
                end;
            }

            action("&Delete Task")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Eliminar Chat';
                Image = Delete;
                ToolTip = 'Elimina los chats seleccionada.';

                trigger OnAction()
                var
                    InteractionMgt: Codeunit "Interaction Mgt.";
                    InteractionLogEntry: Record "Interaction Log Entry";
                begin
                    InteractionLogEntry.SetRange("To-do No.", Rec."No.");
                    if InteractionLogEntry.FindFirst() then begin
                        InteractionLogEntry.DeleteAll();

                    end;
                    Rec.Delete;
                    CurrPage.Update(false);
                end;
            }
            action("&Create Task")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Nuevo Chat';
                Image = NewToDo;
                ToolTip = 'Crea una nueva linea de chat.';

                trigger OnAction()
                var
                    TempTask: Record "To-do" temporary;
                begin
                    If Rec."Contact No." = '' then
                        Rec.Init();
                    If NoEmplazamiento <> '' Then
                        Rec.Emplazamiento := true;
                    Rec.Tabla := Database::"User Task";
                    Rec.Id_Tabla := IdTarea;
                    Rec."Contact No." := NoEmplazamiento;
                    If NoEmplazamiento <> '' then
                        Rec.SetRange("Contact No.", Rec."Contact No.");
                    TempTask.CreateTaskFromTask(Rec);
                end;
            }
            action("Edit Organizer Task")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Editar Organizador de visita';
                Image = Edit;
                RunObject = Page "Task Card";
                RunPageLink = "No." = FIELD("Organizer To-do No.");
                ToolTip = 'Ver información general sobre la tarea, como el tipo, descripción, prioridad y estado de la visita, así como el TECNICO o equipo al que se asigna la visita.';
            }
            // action("Crear Contacto")
            // {
            //     ApplicationArea = All;
            //     Image = NewCustomer;
            //     ShortcutKey = 'Ctrl+N';
            //     trigger OnAction()
            //     var
            //         Res: Record Contact temporary;
            //         Asis: Page "Wizard Contacts";
            //     begin
            //         Res.Init();
            //         Asis.Carga(Res);
            //         Asis.RunModal();

            //     end;
            // }
            // action("Completar Contacto")
            // {
            //     ApplicationArea = All;
            //     Image = NewCustomer;
            //     ShortcutKey = 'Ctrl+N';
            //     trigger OnAction()
            //     var
            //         Res: Record Contact;
            //         Asis: Page "Wizard Contacts";
            //     begin
            //         Res.get(Rec."Contact Company No.");
            //         Asis.Carga(Res);
            //         Asis.RunModal();

            //     end;
            // }



            // action(CreateOpportunity)
            // {
            //     ApplicationArea = RelationshipMgmt;
            //     Caption = 'Crear &Oportunidad';
            //     Gesture = None;
            //     Image = NewOpportunity;


            //     ToolTip = 'Create an opportunity with a specified contact.';

            //     trigger OnAction()
            //     var
            //         InteractionMgt: Codeunit "Interaction Mgt.";
            //         InteractionLogEntry: Record "Interaction Log Entry";
            //     begin
            //         InteractionLogEntry.SetRange("To-do No.", Rec."No.");
            //         If InteractionLogEntry.FindFirst() then begin
            //             InteractionLogEntry.AssignNewOpportunity;
            //             InteractionMgt.ShowNotificationOpportunityCreated(InteractionLogEntry);
            //             CurrPage.Update(false);
            //         end else begin
            //             CreateInteraction();
            //         end;
            //     end;
            // }

        }
        area(Reporting)
        {
            action("Informe Chat")
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    ChatReport: Report "Visitas Emplazamientos";
                    "To-Do": Record "To-do";
                begin
                    "To-Do".SetRange(Tabla, Database::"User Task");
                    "To-Do".SetRange(Id_Tabla, Rec.Id_Tabla);
                    Report.RunModal(Report::"Visitas Emplazamientos", true, true, "To-Do");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref("&Create Task_Promoted"; "&Create Task")
                {
                }
                actionref("Solicit&ar Disponibilidad"; "Solicitar Disponibilidad")
                {
                }
                // actionref("Crear &Oportunidad"; "CreateOpportunity")
                // {
                // }

                // actionref("Crear Ccontacto_Promoted"; "Crear Contacto") { }

            }
        }

    }

    local procedure CreateInteraction()
    var
        TempSegLine: Record "Segment Line" temporary;
    begin
        if Rec.Type = Rec.Type::"Phone Call" then begin
            TempSegLine."Campaign No." := Rec."Campaign No.";
            TempSegLine."Opportunity No." := Rec."Opportunity No.";
            TempSegLine."Contact No." := Rec."Contact No.";
            TempSegLine."To-do No." := Rec."No.";
            TempSegLine."Salesperson Code" := Rec."Salesperson Code";
            TempSegLine.CreatePhoneCall;
        end else
            TempSegLine.CreateInteractionFromTask(Rec);
    end;

    var
        "C.I.F.": Text;
        Cont: Record Contact;
        Contact1: Record Contact;
        Salesperson: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
        Team: Record Team;
        Opp: Record Opportunity;
        SegHeader: Record "Segment Header";
        RecordsFound: Boolean;
        Text000: Label '(Multiple)';
        Text001: Label 'untitled';
        Text004: Label 'The Make Phone Call function for this task is available only on the Attendee Scheduling window.';
        Text005: Label 'You must select a task with a contact assigned to it before you can use the Make Phone Call function.';
        Objetosocial: Text;
        NoEmplazamiento: Code[20];
        IdTarea: RecordId;

    procedure CargarEmplazamiento(pNoEmplazamiento: Code[20]; pId_Tarea: RecordId)
    begin
        NoEmplazamiento := pNoEmplazamiento;
        IdTarea := pId_Tarea;
        Rec.Setrange(Tabla, Database::"User Task");
        Rec.Setrange(Id_Tabla, IdTarea);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.Tabla := Database::"User Task";
        Rec.Id_Tabla := IdTarea;
    end;

    procedure ProcedureTarea(Id: RecordId; Campo: Text): Text;
    var
        Tarea: Record "User Task";
        Resource: Record "Resource";
        Emplazamiento: Record "Emplazamientos";
        Pnel: Record PNEL;
        User: Record User;
    begin
        If Not Tarea.Get(Id) then
            exit('');
        Case Campo of
            'Descripcion':
                exit(Tarea.GetDescription());
            'Descripcion Emplazamiento':
                begin
                    Case Tarea."Object ID" of
                        Page::"Resource Card":
                            begin
                                If Resource.Get(Tarea.Id_record) then
                                    If Emplazamiento.Get(Resource."Nº Emplazamiento") then
                                        exit(Emplazamiento."Nº Emplazamiento" + ' - ' + Emplazamiento."Descripción");
                            end;
                        Page::"PNEL Emplazamientos":
                            begin
                                If Pnel.Get(Tarea.Id_record) then
                                    If Emplazamiento.Get(Pnel."Nº Emplazamiento") then
                                        exit(Emplazamiento."Nº Emplazamiento" + ' - ' + Emplazamiento."Descripción");
                            end;
                        Page::"Ficha emplazamiento":
                            begin
                                If Emplazamiento.Get(Tarea.Id_record) then
                                    exit(Emplazamiento."Nº Emplazamiento" + ' - ' + Emplazamiento."Descripción");
                            end;
                    End;
                end;
            'Responsable':
                begin
                    If User.Get(Tarea."Assigned To") then
                        exit(User."Full Name");
                end;
            'Supervisor':
                begin
                    If User.Get(Tarea.Supervisor) then
                        exit(User."Full Name");
                end;
        End;

    end;

    trigger OnOpenPage()
    var
        UserSetup: Record "User Setup";
    begin

        // If UserSetup.Get(UserId) Then begin
        //     If UserSetup."Salespers./Purch. Code" <> '' then
        //         Rec.SetRange("Salesperson Code", UserSetup."Salespers./Purch. Code");
        // end;
        Rec.SetRange(Emplazamiento, true);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        UserSetup: Record "User Setup";
    begin
        If UserSetup.Get(UserId) Then
            Rec."Salesperson Code" := UserSetup."Salespers./Purch. Code";
        UserSetup.TestField("Salespers./Purch. Code");
        Rec.Date := Today;
        Rec.Emplazamiento := true;
    end;

    trigger OnAfterGetRecord()
    var
        Contact: Record Contact;
    begin
        if Rec."Contact Company No." <> '' then begin
            Contact.Get(Rec."Contact Company No.");
            Objetosocial := Contact."Objeto Social";
        end;
    end;

    local procedure SolicitarDisponibilidad()
    var
        Mail: Codeunit Mail;
        Salesperson2: Record "Salesperson/Purchaser";
        Task2: Record "To-do";
        Body: Text;
        BigText: Text;
        REmail: Record "Email Item" temporary;
        emilesc: Enum "Email Scenario";
        rInf: Record "Company Information";
        Funciones: Codeunit "Funciones Correo PDF";
        base64: Text;
    begin
        Salesperson2.Get(Rec."Salesperson Code");
        Task2.Get(Rec."No.");
        rInf.Get();
        Task2.CalcFields("Contact Company Name");
        BigText := ('Estimado compañero:');

        //(FORMAT(cr,0,'<CHAR>') + FORMAT(lf,0,'<CHAR>')
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        //BigText:=('<br> </br>';
        BigText := BigText + ('Necesitaría que me confirmaras la disponibilidad de una serie de recursos asociados a la tarea ');
        BigText := BigText + (' nº. <b>' + Task2."No." + '</b> de fecha ');
        BigText := BigText + (FORMAT(Today, 0, '<Day,2>/<Month,2>/<Year>'));
        BigText := BigText + (' correspondiente al cliente ' + Task2."Contact Company Name");
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + ('Aprovechamos la ocasión para enviarte un cordial saludo');
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + ('Atentamente');
        BigText := BigText + '<br> </br>';
        BigText := BigText + (Salesperson2.Name);
        BigText := BigText + '<br> </br>';

        BigText := BigText + (rInf.Name);
        //"Plaintext Formatted":=TRUE;
        // SendMsg.AppendBody(BigText);
        // CLEAR(BigText);
        REmail.AddAttachment(Funciones.CargaPie(base64), 'emailfoot.png');
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<img src="data:image/jpeg;base64,+' + base64 + '" />';//"emailFoot.png" />';
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<font face="Franklin Gothic Book" sice=2 color=Blue>';
        BigText := BigText + ('<b>SI NO DESEA RECIBIR MAS INFORMACION, CONTESTE ESTE E-MAIL INDICANDOLO EXPRESAMENTE</b>');
        BigText := BigText + '</font>';
        BigText := BigText + '<br> </br>';
        BigText := BigText + '<font face="Franklin Gothic Book" size=1 color=Blue>';
        BigText := BigText + ('Según la LOPD 15/199, su dirección de correo electrónico junto a los demás datos personales');
        BigText := BigText + (' que Ud. nos ha facilitado, constan en un fichero titularidad de ');
        BigText := BigText + (rInf.Name + ', cuyas finalidades son mantener la');
        BigText := BigText + (' gestión de las comunicaciones con sus clientes y con aquellas personas que solicitan');
        BigText := BigText + (' información, así como la gestión y atención de los correos entrantes o sugerencias que');
        BigText := BigText + (' se formulen a través de esta cuenta derivados de su actividad. Podrá ejercitar los derechos');
        BigText := BigText + (' de acceso, cancelación, rectificación y oposición,  dirigiéndose, por escrito a ');
        BigText := BigText + (rInf.Name + ' . ' + rInf.Address + '. ' + rInf."Post Code" + '. ' + rInf.City + '. España');

        BigText := BigText + '<br> </br>';
        //SendMsg.AppendBody(BigText);
        //CLEAR(BigText);
        BigText := BigText + ('Este correo y sus archivos asociados son privados y confidenciales y va');
        BigText := BigText + (' dirigido exclusivamente a su destinatario. Si recibe este correo sin ser');
        BigText := BigText + (' el destinatario del mismo, le rogamos proceda a su eliminación y lo ponga');
        BigText := BigText + (' en conocimiento del emisor. La difusión por cualquier medio del contenido de este');
        BigText := BigText + (' correo podría ser sancionada conforme a lo previsto en las leyes españolas. ');
        BigText := BigText + ('No se autoriza la utilización con fines comerciales o para su incorporación a ficheros');
        BigText := BigText + (' automatizados de las direcciones del emisor o del destinatario.');
        BigText := BigText + '</font>';
        REmail.Subject := 'Petición disponibilidad tarea nº ' + Task2."No.";

        REmail."Send to" := 'julian@malla.es';
        REmail."Send CC" := 'ana@malla.es;marian@malla.es;miguel@malla.es';
        REmail."Send BCC" := Salesperson2."E-Mail";
        REmail.SetBodyText(BigText);
        REmail."From Address" := Salesperson2."E-Mail";
        REmail."From Name" := Salesperson2.Name;
        // if REmail."From Address" <> '' Then
        //     REmail."Send BCC" := REmail."From Address" else
        //     REmail."Send BCC" := BCC();
        if REmail.Send(false, emilesc::Comercial) then begin
            Task2."Peticion disponibilidad" := Task2."Peticion Disponibilidad"::"Peticion Enviada";
            Task2.Modify(true);
        end;
    end;
}
