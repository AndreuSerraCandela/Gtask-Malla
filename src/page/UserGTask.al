//Crear page
page 7001184 "UsuariosGtask"
{
    PageType = List;
    SourceTable = UsuariosGtask;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'Usuarios Gtask';
    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Id Usuario"; Rec."Id Usuario")
                {
                    ApplicationArea = All;
                }
                field("Nombre"; Rec."Nombre")
                {
                    ApplicationArea = All;
                }
                field("Apellido"; Rec."Apellido")
                {
                    ApplicationArea = All;
                }
                field("Email"; Rec."Email")
                {
                    ApplicationArea = All;
                }
                field("Teléfono"; Rec."Teléfono")
                {
                    ApplicationArea = All;
                }
                field("Id Gtask"; Rec."Id Gtask")
                {
                    ApplicationArea = All;
                }
                field("Departamento"; Rec."Departamento")
                {
                    ApplicationArea = All;
                }
                field(Grupo; Rec.Grupo)
                {
                    ApplicationArea = All;
                }
                field("Puede crear dosieres"; Rec."Puede crear dosieres")
                {
                    ApplicationArea = All;
                    ToolTip = 'Permite al usuario crear nuevos dosieres desde la aplicación Dosiers.';
                }
                field("Responsable"; Rec."Responsable")
                {
                    ApplicationArea = All;
                }
                field("Supervisor"; Rec."Supervisor")
                {
                    ApplicationArea = All;
                }
                field("Empleado"; Rec."Empleado")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nº de empleado asociado al usuario GTask.';
                    trigger OnAssistEdit()
                    var
                        Employee: Record Employee;
                        EmployeeList: Page "Employee List";
                    begin
                        Rec.TestField("Id Gtask");
                        Employee.ChangeCompany('Malla Publicidad');
                        EmployeeList.LookupMode := true;
                        if EmployeeList.RunModal() = Action::LookupOK then begin
                            EmployeeList.SetSelectionFilter(Employee);
                            if Employee.FindSet() then
                                repeat
                                    Employee.UserGtask := Rec."Id Gtask";
                                    Employee.Modify(true);
                                until Employee.Next() = 0;
                        end;
                    end;
                }
                field("Usuario EMT"; Rec."Usuario EMT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre de usuario de la app EMT para vincular incidencias comunicadas por EMT.';
                }
                // field("Id Usuario Limpieza EMT"; Rec."Id Usuario Limpieza EMT")
                // {
                //     ApplicationArea = All;
                // }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Crear Usuarios BC")
            {
                ApplicationArea = All;
                Caption = 'Crear Usuarios BC';
                Image = Import;
                trigger OnAction()
                var
                    UsuariosGtask: Record "UsuariosGtask";
                    User: Record User;
                    Gtask: Codeunit Gtask;
                begin
                    UsuariosGtask.ChangeCompany('Malla Publicidad');
                    Gtask.CreateUsers(UsuariosGtask);
                    Commit();
                    if UsuariosGtask.FindSet() then
                        repeat
                            User.SetRange("Contact Email", UsuariosGtask."Email");
                            If (Not User.FindFirst()) And (not User.Get(UsuariosGtask."Id Usuario")) then begin
                                User.Init();
                                user.Validate("User Name", UsuariosGtask."Nombre" + ' ' + UsuariosGtask."Apellido");
                                User."User Security ID" := CreateGuid();
                                UsuariosGtask."Id Usuario" := User."User Security ID";
                                User."License Type" := User."License Type"::"External User";
                                User."Full Name" := UsuariosGtask."Nombre";
                                User."Contact Email" := UsuariosGtask."Email";
                                User.Insert(true);
                                UsuariosGtask.Modify(true);
                            end;
                        until usuariosGtask.next = 0;
                end;
            }
        }
    }
}
