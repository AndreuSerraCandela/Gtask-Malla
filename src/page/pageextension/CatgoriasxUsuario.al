pageextension 92152 "Usuarios x Categoría" extends "User Task Group Members"
{
    layout
    {
        modify("User Name")
        {
            Visible = false;
        }


        addafter("User Name")
        {
            //     field("Zona Limpieza"; Rec."Zona Limpieza")
            //     {
            //         ApplicationArea = All;
            //     }

            field(Usuario; Rec.Usuario)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies a user that is a member of the group.';

                trigger OnAssistEdit()
                var
                    User: Record UsuariosGtask;
                    Users: Page UsuariosGtask;
                begin
                    User.ChangeCompany('Malla Publicidad');
                    User.SetRange("Id Usuario", Rec."User Security ID");
                    if User.FindFirst() then
                        Users.SetRecord(User);

                    Users.LookupMode := true;
                    if Users.RunModal() = ACTION::LookupOK then begin
                        Users.GetRecord(User);
                        Rec."User Security ID" := User."Id Usuario";
                        CurrPage.Update(true);
                    end;
                end;

            }

            field(Departmento; Rec.DepartAmento)
            {
                ApplicationArea = All;
            }
            field("Responsable"; Rec."Responsable")
            {
                ApplicationArea = All;
            }
            field("Supervisor"; Rec."Supervisor")
            {
                ApplicationArea = All;
            }
            field("Copiado en Mail"; Rec."Copiado en Mail")
            {
                ApplicationArea = All;
            }



        }
    }
}