pageextension 92154 "UserTask" extends "User Task card"
{
    layout
    {
        modify("Assigned To User Name")
        {
            Visible = false;
        }
        addbefore("Percent Complete")
        {
            field(Estado; Rec.Estado)
            {
                ApplicationArea = All;
            }
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
        addafter("Due DateTime")
        {
            group(RecurrenciaAviso)
            {
                Caption = 'Recurrencia y aviso';

                field(RecurrenciaActiva; Rec.RecurrenciaActiva)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Indica si la tarea tiene recurrencia configurada.';
                }
                field(TextoRecurrencia; Rec.TextoRecurrencia)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Resumen de la recurrencia guardada en esta tarea.';
                }
                field(FechaAviso; Rec.FechaAviso)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Día en que se enviará el correo de aviso al responsable.';
                }
                field(Avisar; Rec.Avisar)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
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
                    ActualizarChecklist();
                    CurrPage.Update(false);
                end;
            }
            field(Job; Rec."Job No.")
            {
                Caption = 'Nº Proyecto';
                ApplicationArea = All;
            }
            field("Tipo objetivo"; Rec."Tipo objetivo")
            {
                ApplicationArea = All;
            }
            field("Veces objetivo"; Rec."Veces objetivo")
            {
                ApplicationArea = All;
            }
            field("Periodo objetivo"; Rec."Periodo objetivo")
            {
                ApplicationArea = All;
            }
        }

        addlast(Content)
        {
            group(Checklist)
            {
                Caption = 'Checklist';
                Visible = MostrarChecklist;

                part(ChecklistTareaUsuario; "Checklist Tarea Usuario")
                {
                    ApplicationArea = All;
                    Caption = 'Checklist';
                    SubPageLink = Id = field(ID), "Categoría" = field("User Task Group Assigned To");
                    UpdatePropagation = Both;
                }
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
        modify(Recurrence)
        {
            Visible = false;
        }
        modify(Recurrence_Promoted)
        {
            Visible = false;
        }
        addafter(Recurrence)
        {
            action(RecurrenciaGtask)
            {
                ApplicationArea = All;
                Caption = 'Recurrencia';
                Image = Refresh;
                ToolTip = 'Configura la recurrencia, los campos personalizados que se copiarán y el aviso por correo.';

                trigger OnAction()
                var
                    RecurrenciaPage: Page "Recurrencia Tarea Gtask";
                begin
                    RecurrenciaPage.SetRecord(Rec);
                    RecurrenciaPage.RunModal();
                    CurrPage.Update(false);
                end;
            }
        }
        addafter("Go To Task Item")
        {
            //hABILITAR pARA CREAR PARTE DE TRABAJO
            action(CreateParte)
            {
                ApplicationArea = All;
                Caption = 'Permitir Parte de Trabajo';
                Image = Create;
                trigger OnAction()
                begin
                    Rec.CrearParte := true;
                    Rec.Modify();
                end;
            }

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
                    Procesos_GTask: Codeunit Procesos_GTask;
                begin
                    Procesos_GTask.Email(Rec, EmailResponsable, EmailSupervisor);
                    User.SetRange("User Security ID", Rec."Assigned To");
                    User.FindFirst();
                    If Rec.RecordId.TableNo = Database::Emplazamientos Then
                        Procesos_GTask.EnviaCorreoEmplazamiento(Rec."No.", Rec.GetDescription(), true, '', false, Rec.Title, EmailResponsable, EmailSupervisor, '', '', User."Full Name", false, Rec.Id_Tarea, false, false, Rec.RecordId)
                    else
                        Procesos_GTask.EnviaCorreo(Rec."No.", Rec.GetDescription(), true, '', false, Rec.Title, EmailResponsable, EmailSupervisor, '', '', User."Full Name", false, Rec.Id_Tarea, false, false);
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
                                    Emplazamiento := Emplazamientos."Nº Emplazamiento"
                                else begin
                                    //Emplazamientos: 7059
                                    //1234567890123456
                                    Emplazamiento := Copystr(Format(Rec.Id_record), 17, 10);
                                    Emplazamientos.SetRange("Nº Emplazamiento", Emplazamiento);
                                    if Emplazamientos.FindFirst() then
                                        Emplazamiento := Emplazamientos."Nº Emplazamiento"
                                    else
                                        Emplazamiento := '0' + Emplazamiento;
                                end;
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
            actionref(RecurrenciaGtask_Promoted; RecurrenciaGtask) { }
            actionref(Visitas_Ref; Visitas) { }
            actionref(CreateParte_Ref; CreateParte) { }

            actionref(Finish_Promoted; Finish) { }
            actionref(Delete_Promoted; Delete) { }
        }


    }
    trigger OnAfterGetRecord()
    begin
        If Rec.Estado = Rec.Estado::Pendiente then
            If not Rec.EsPeriodica then
                Rec.EliminarTarea := true;
        if Rec."No." = '' then begin
            Rec."No." := Format(Rec.ID);
            Rec.Modify();
        end;
        Rec.ActualizarFechaAviso();
        ActualizarChecklist();
    end;

    trigger OnOpenPage()
    begin
        if Rec."Categoría" <> '' then begin
            Eventos(Rec."Categoría");
            ActualizarChecklist();
            CurrPage.Update(false);
        end;
    end;

    Procedure Eventos(pCategoria: Code[20])
    var
        Procesos_GTask: Codeunit Procesos_GTask;

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
        Procesos_GTask.DevuelveSupervisoryResponsable(Responsable, Supervisor, Departamento, Servicio, pCategoria, EmailResponsable,
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

    local procedure ActualizarChecklist()
    var
        ChecklistTareaUsuario: Record "Checklist Tarea Usuario";
        CategoriaChecklist: Code[20];
    begin
        MostrarChecklist := false;

        CategoriaChecklist := Rec."User Task Group Assigned To";
        if CategoriaChecklist = '' then
            CategoriaChecklist := Rec."Categoría";
        if CategoriaChecklist = '' then
            exit;

        MostrarChecklist := ChecklistTareaUsuario.TienePlantilla(CategoriaChecklist);
        if not MostrarChecklist then
            exit;

        ChecklistTareaUsuario.CrearDesdePlantilla(Rec.ID, CategoriaChecklist);
    end;

    local procedure FinishPage(Borrar: Text)
    var
        Gtask: Codeunit Gtask;
        RecRef: RecordRef;
        Resource: Record Resource;
    begin
        If Borrar = 'Delete' then
            REC.EliminarTarea := true
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
        MostrarChecklist: Boolean;


}
