pageextension 92154 "UserTask" extends "User Task card"
{
    layout
    {
        modify("Assigned To User Name")
        {
            Visible = false;
        }
        addbefore("created by User Name")
        {
            field(Responsable; Rec."Assigned To User Name")
            {
                Caption = 'Responsable';
                ApplicationArea = Basic, Suite;
                DrillDown = true;
                ToolTip = 'Responsable de la tarea';


                trigger OnAssistEdit()
                var
                    User: Record UsuariosGtask;
                    Users: Page UsuariosGtask;
                begin
                    User.ChangeCompany('Malla Publicidad');
                    User.SetRange("Id Usuario", Rec."Assigned To");
                    if User.FindFirst() then begin
                        User.SetRange("Id Usuario");
                        User.Get(User."Id Gtask");
                        Users.SetRecord(User);
                    end;

                    Users.LookupMode := true;
                    if Users.RunModal() = ACTION::LookupOK then begin
                        Users.GetRecord(User);
                        Rec."Assigned To" := User."Id Usuario";
                        Rec.CalcFields("Assigned To User Name");
                        CurrPage.Update(true);
                        Rec."Assigned To" := User."Id Usuario";
                        Rec.Modify();
                    end;
                end;

            }
            field(Supervisor; Rec."Supervisor User Name")
            {
                Caption = 'Supervisor';
                ApplicationArea = Basic, Suite;
                DrillDown = true;
                ToolTip = 'Especifique el supervisor de la tarea';

                trigger OnAssistEdit()
                var
                    User: Record UsuariosGtask;
                    Users: Page UsuariosGtask;
                begin
                    User.SetRange("Id Usuario", Rec.Supervisor);
                    if User.FindFirst() then begin
                        User.SetRange("Id Usuario");
                        User.Get(User."Id Gtask");
                        Users.SetRecord(User);
                    end;

                    Users.LookupMode := true;
                    if Users.RunModal() = ACTION::LookupOK then begin
                        Users.GetRecord(User);
                        Rec.Supervisor := User."Id Usuario";
                        Rec.CalcFields("Supervisor User Name");
                        CurrPage.Update(true);
                        Rec.Supervisor := User."Id Usuario";
                        Rec.Modify();
                    end;
                end;

            }
            field(Departamento; Rec.Departamento)
            {
                ApplicationArea = All;
            }
            field(Servicio; Rec.Servicio)
            {
                ApplicationArea = All;
            }
        }
        modify("User Task Group Assigned To")
        {
            Visible = false;

        }
        addafter("User Task Group Assigned To")
        {
            field(Categoria; Rec."Categoría")
            {
                Caption = 'Categoría';
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    Eventos(Rec."Categoría");
                end;
            }
            field(Job; Rec."Job No.")
            {
                Caption = 'Nº Proyecto';
                ApplicationArea = All;
            }
        }

        addfirst(FactBoxes)
        {
            part(DocumentAttach; "Doc. Attachment List FactBox")
            {
                ApplicationArea = All;
                Caption = 'Documentos Adjuntos';
                SubPageLink = "No." = field("No."), "Table ID" = const(Database::"User Task");
            }

        }


    }
    actions
    {
        addafter("Go To Task Item")
        {
            action(Finish)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Guardar y cerrar';
                Image = Approve;
                InFooterBar = true;
                ToolTip = 'Finaliza la tarea y la guarda.';
                Visible = true;

                trigger OnAction()
                begin
                    FinishPage('Finalizar');
                    CurrPage.Close();
                end;
            }
            action(Delete)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Borrar';
                Image = Delete;
                InFooterBar = true;
                ToolTip = 'Borra la tarea.';
                Visible = true;

                trigger OnAction()
                begin
                    FinishPage('Delete');
                    CurrPage.Close();
                end;
            }
            action("Delete&Create")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Borrar y volver a crear';
                Image = Recalculate;
                InFooterBar = true;
                ToolTip = 'Borra la tarea y la vuelve a crear.';
                Visible = true;

                trigger OnAction()
                begin
                    Rec.Id_Tarea := '';
                    FinishPage('Recrear');
                    CurrPage.Close();
                end;
            }
            action("Enviar Correo")
            {
                ApplicationArea = All;
                Image = Email;
                Caption = 'Enviar Correo';
                trigger OnAction()
                var
                    Gtask: Codeunit Gtask;
                begin
                    Gtask.Email(Rec, EmailResponsable, EmailSupervisor);
                    User.SetRange("User Security ID", Rec."Assigned To");
                    User.FindFirst();
                    Gtask.EnviaCorreo(Rec."No.", Rec.GetDescription(), true, '', false, Rec.Title, EmailResponsable, EmailSupervisor, '', '', User."Full Name", false, Rec.Id_Tarea, false);
                end;
            }


            action(Visitas)
            {
                ApplicationArea = All;
                Image = ContactPerson;
                Caption = 'Chat Tarea';
                trigger OnAction()
                var
                    Visitas: Page "Chat Tareas";
                    "To-Do": Record "To-do";
                    Resource: Record "Resource";
                    Pnel: Record "PNEL";
                    Emplazamientos: Record "emplazamientos";
                    Emplazamiento: Code[20];
                begin
                    "To-Do".SetRange(id_Tabla, Rec.RecordId);
                    "To-Do".SetRange("Tabla", Database::"User Task");
                    Case Rec."Object ID" of
                        Page::"Resource Card":
                            begin
                                If Resource.Get(Rec.Id_record) then
                                    Emplazamiento := (Resource."Nº Emplazamiento");
                            end;
                        Page::"PNEL Emplazamientos":
                            begin
                                If Pnel.Get(Rec.Id_record) then
                                    Emplazamiento := Pnel."Nº Emplazamiento";
                            end;
                        Page::"Ficha emplazamiento":
                            begin
                                If Emplazamientos.Get(Rec.Id_record) then
                                    Emplazamiento := Emplazamientos."Nº Emplazamiento";
                            end;
                    End;
                    Visitas.CargarEmplazamiento("Emplazamiento", Rec.RecordID);
                    Visitas.SetTableView("To-Do");
                    Visitas.RunModal();

                end;
            }
        }
        addbefore(Recurrence_Promoted)
        {
            actionref(Visitas_Ref; Visitas) { }

            actionref(Finish_Promoted; Finish) { }
            actionref(Delete_Promoted; Delete) { }
        }


    }
    trigger OnAfterGetRecord()
    var
        NullFrecuencia: DateFormula;
    begin
        If Rec.Estado = Rec.Estado::Pendiente then
            If Rec.Frecuencia = NullFrecuencia then
                Rec.Estado := Rec.Estado::Cancelado;
        if Rec."No." = '' then begin
            Rec."No." := Format(Rec.ID);
            Rec.Modify();
        end;
    end;

    Procedure Eventos(pCategoria: Code[20])
    var
        Gtask: Codeunit Gtask;

        RecRef: RecordRef;
        Resource: Record "Resource";
        UserxbyCategory: Record "User Task Group Member";
    begin
        Rec."User Task Group Assigned To" := pCategoria;
        Rec."Categoría" := pCategoria;
        Rec.Modify();
        Commit();
        UserxbyCategory.SetRange(Responsable, true);
        UserxbyCategory.SetRange("User Task Group Code", pCategoria);
        If UserxbyCategory.FindFirst() Then Departamento := UserxbyCategory."Departamento";
        UserxbyCategory.Reset();
        UserxbyCategory.SetRange(Supervisor, true);
        UserxbyCategory.SetRange("User Task Group Code", pCategoria);
        If UserxbyCategory.FindFirst() Then Servicio := UserxbyCategory.Departamento;
        User.Get(UserSecurityId());
        Gtask.DevuelveSupervisoryResponsable(Responsable, Supervisor, Departamento, Servicio, pCategoria, EmailResponsable,
        EmailSupervisor, User, Rec, ListadeCorreos);
        CurrPage.UPDATE(false);

    end;

    procedure DevuelveSupervisoryResponsable(var pResponsable: Guid;
    var pSupervisor: Guid; var pDepartamento: Code[20];
    var pServicio: Code[20]; var pCategoria: Code[20];
    var pEmailResponsable: Text; var pEmailSupervisor: Text;
    var pListadeCorreos: Text)
    begin
        pCategoria := Rec."Categoría";
        pSupervisor := Supervisor;
        pResponsable := Responsable;
        pDepartamento := Departamento;
        pServicio := Servicio;
        pEmailResponsable := EmailResponsable;
        pEmailSupervisor := EmailSupervisor;
        pListadeCorreos := ListadeCorreos;
    end;

    local procedure FinishPage(Borrar: Text)
    var
        Gtask: Codeunit Gtask;
        RecRef: RecordRef;
        Resource: Record Resource;
    begin
        If Borrar = 'Delete' then
            REC.Estado := Rec.Estado::Cancelado
        else
            Rec.Estado := Rec.Estado::Pendiente;
        Rec.Modify();

        if Borrar = 'Recrear' then begin
            Rec.Get(Rec."No.");
            Resource.Init;
            Case Rec."Object ID" of
                Page::"Resource Card":
                    begin
                        If Resource.Get(Rec.Id_record) then;
                    end;
            End;
            Gtask.CrearTareaTecnico(Resource."No.", Rec, Rec.Departamento, Rec.Servicio, false);
            Rec.Get(Rec."No.");
        end;

    end;

    var
        Responsable: Guid;
        Supervisor: Guid;
        Departamento: Code[20];
        Servicio: Code[20];
        EmailResponsable: Text;
        EmailSupervisor: Text;
        User: Record User;
        ListadeCorreos: Text;


}
