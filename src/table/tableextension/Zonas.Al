tableextension 92406 Zonas extends "Zonas Recursos"
{
    fields
    {
        field(92000; Equipo; Text[50])
        {
            TableRelation = UsuariosGtask."Id Gtask";
        }

    }
}