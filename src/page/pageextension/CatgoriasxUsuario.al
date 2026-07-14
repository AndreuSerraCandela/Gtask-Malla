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

            field("Usuario GTask"; Procdure_User())
            {
                ApplicationArea = ALL;
                ToolTip = 'Specifies a user that is a member of the group.';

                trigger OnAssistEdit()
                var
                    User: Record UsuariosGtask;
                //Users: Page UsuariosGtask;
                begin
                    User.ChangeCompany('Malla Publicidad');
                    if Page.RunModal(Page::"UsuariosGtask", User) = ACTION::LookupOK then begin
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
            field("Enviar Whatsapp"; Rec."Enviar Whatsapp")
            {
                ApplicationArea = All;
                Caption = 'Enviar Whatsapp';
            }

        }
    }

    local procedure Procdure_User(): Text
    begin
        Rec.CalcFields(Usuario);
        exit(Rec.Usuario);
    end;
}