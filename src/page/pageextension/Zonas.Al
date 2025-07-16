pageextension 92167 ZonasExt extends "Zonas Recursos"
{
    layout
    {
        addlast(Detalle)
        {

            field("Equipo"; Rec.Equipo)
            {
                ApplicationArea = All;
            }


        }
    }


}