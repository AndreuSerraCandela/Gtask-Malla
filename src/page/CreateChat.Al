page 50105 "Create Chat"
{
    Caption = 'Crear Chat';
    DataCaptionExpression = Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "To-do";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(TipoSaaS; Tipo)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Tipo';
                    ToolTip = 'Especifica el tipo de tarea';
                    Visible = IsSoftwareAsAService;

                    trigger OnValidate()
                    begin
                        case Tipo of
                            Tipo::Chat:
                                Rec.Type := Rec.Type::"Phone Call";
                            Tipo::Reunion:
                                Rec.Type := Rec.Type::Meeting;
                        end;
                        IsMeeting := (Rec.Type = Rec.Type::Meeting);
                        ValidateTypeField();
                    end;
                }
                field(TipoOnPrem; Tipo)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Tipo';
                    ToolTip = 'Especifica el tipo de tarea';
                    Visible = not IsSoftwareAsAService;

                    trigger OnValidate()
                    begin
                        case Tipo of
                            Tipo::Chat:
                                Rec.Type := Rec.Type::"Phone Call";
                            Tipo::Reunion:
                                Rec.Type := Rec.Type::Meeting;
                        end;
                        IsMeeting := (Rec.Type = Rec.Type::Meeting);
                        ValidateTypeField();
                    end;
                }
                field(Description; Rec."Descripción Visita")
                {
                    Caption = 'Descripción';
                    MultiLine = true;
                    ApplicationArea = All;
                    ToolTip = 'Especifica la descripción de la tarea.';
                }
                field(AllDayEvent; Rec."All Day Event")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = IsMeeting;
                    Caption = 'Evento de todo el día';
                    Enabled = AllDayEventEnable;
                    ToolTip = 'Especifica si la tarea es un evento de todo el día.';

                    trigger OnValidate()
                    begin
                        AllDayEventOnAfterValidate();
                    end;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Fecha';
                    ToolTip = 'Especifica la fecha en la que se debe completar la tarea. Hay ciertas reglas para cómo se deben ingresar las fechas. Para obtener más información, consulte Cómo: Ingresar fechas y horas.';
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Hora de inicio';
                    Enabled = StartTimeEnable;
                    ToolTip = 'Especifica la hora de inicio de la tarea.';
                    Visible = IsMeeting;
                }
                field(Duration; Rec.Duration)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Duración';
                    Enabled = DurationEnable;
                    ToolTip = 'Especifica la duración de la tarea.';
                    Visible = IsMeeting;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Fecha de finalización';
                    ToolTip = 'Especifica la fecha en la que se debe completar la tarea.';
                    Visible = IsMeeting;
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Hora de finalización';
                    Enabled = EndingTimeEnable;
                    ToolTip = 'Especifica la hora de finalización de la tarea.';
                    Visible = IsMeeting;
                }
                field(TeamTask; Rec."Team To-do")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Tarea de equipo';
                    ToolTip = 'Especifica si la tarea es para un equipo.';
                    Visible = IsMeeting;
                    trigger OnValidate()
                    begin
                        if not Rec."Team To-do" then begin
                            Rec."Team Code" := '';
                            SalespersonCodeEnable := true;
                            if Rec.Type = Rec.Type::Meeting then begin
                                Rec.ClearDefaultAttendeeInfo();
                                Rec.AssignDefaultAttendeeInfo();
                            end;
                        end else begin
                            SalespersonCodeEnable := false;
                            Rec."Salesperson Code" := '';
                        end;
                    end;
                }
                field("Wizard Contact Name"; Rec."Wizard Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Emplazamiento';
                    Editable = WizardContactNameEditable;
                    Enabled = WizardContactNameEnable;
                    Lookup = false;
                    TableRelation = Emplazamientos;
                    ToolTip = 'Especifica el emplazamiento';

                    trigger OnAssistEdit()
                    var
                        Cont: Record Emplazamientos;
                        Emplazamientos: Codeunit "Emplazamientos";
                        IsHandled: Boolean;
                    begin
                        if (Rec.GetFilter("Contact No.") = '') and (Rec.GetFilter("Contact Company No.") = '') and (Rec."Segment Description" = '') then begin
                            Cont.Reset();
                            Cont.SetRange("Nº Emplazamiento", Rec."Contact No.");
                            if Cont.FindFirst() then;
                            if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                                Rec."Contact No." := Cont."Nº Emplazamiento";
                                Emplazamientos.OnBeforeValidateContactNo(Rec, Rec, IsHandled);
                                Rec."Wizard Contact Name" := Cont."Descripción";
                                Rec."Contact Company No." := '';
                                rec.Location := Cont.Calle;
                            end;
                        end;
                        CurrPage.AttendeeSubform.Page.SetContactNo(Rec."Contact No.");
                    end;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'TECNICO';
                    Enabled = SalespersonCodeEnable;
                    ToolTip = 'Espcifica el TECNICO que se encargará de la tarea.';
                }
                field("Team Code"; Rec."Team Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Equipo';
                    Editable = Rec."Team To-do";
                    Enabled = Rec."Team To-do" or not IsMeeting;
                    ToolTip = 'especifica el equipo que se encargará de la tarea.';

                    trigger OnValidate()
                    begin
                        if (xRec."Team Code" <> Rec."Team Code") and
                           (Rec."Team Code" <> '') and
                           (Rec.Type = Rec.Type::Meeting)
                        then begin
                            Rec.ClearDefaultAttendeeInfo();
                            Rec.AssignDefaultAttendeeInfo();
                        end
                    end;
                }
                field(Priority; Rec.Priority)
                {
                    Visible = IsMeeting;
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Prioridad';
                    Importance = Additional;
                    ToolTip = 'Especifica la prioridad de la tarea.';
                }

            }
            group(MeetingAttendees)
            {
                Caption = 'Asistentes';
                Visible = IsMeeting;
                part(AttendeeSubform; "Attendee Empl. Wizard Subform")
                {
                    Caption = 'Especifica los asistentes de la visita.';
                    ApplicationArea = RelationshipMgmt;
                    SubPageLink = "To-do No." = FIELD("No.");
                }
                group(MeetingInteraction)
                {
                    Caption = 'Interacción';
                    field("Send on finish"; Rec."Send on finish")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Enviar al finalizar';
                        ToolTip = 'Especifica si se debe enviar la tarea al finalizarla.';
                    }
                    field("Interaction Template Code"; Rec."Interaction Template Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Plantilla de interacción';
                        TableRelation = "Interaction Template";
                        ToolTip = 'Especifica la plantilla de interacción que se utilizará para la tarea.';

                        trigger OnValidate()
                        begin
                            Rec.ValidateInteractionTemplCode();
                            InteractionTemplateCodeOnAfter();
                        end;
                    }
                    field("Language Code"; Rec."Language Code")
                    {
                        Caption = 'Código de idioma';
                        ApplicationArea = RelationshipMgmt;
                        Enabled = LanguageCodeEnable;
                        ToolTip = 'Especifica el idioma en el que se enviará la tarea.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Rec.LookupLanguageCode();
                        end;

                        trigger OnValidate()
                        begin
                            Rec.ValidateLanguageCode();
                        end;
                    }
                    field(Attachment; Rec."Attachment No." > 0)
                    {
                        ApplicationArea = RelationshipMgmt;
                        AssistEdit = true;
                        Caption = 'Adjunto';
                        Editable = false;
                        Enabled = AttachmentEnable;
                        ToolTip = 'Especifica el adjunto que se enviará con la tarea.';

                        trigger OnAssistEdit()
                        begin
                            Rec.AssistEditAttachment();
                        end;
                    }
                }
            }
            group(RecurringOptions)
            {
                Caption = 'Opciones recurrentes';
                Visible = IsMeeting;
                field(Recurring; Rec.Recurring)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Recurrente';
                    ToolTip = 'Especifica si la tarea es recurrente.';

                    trigger OnValidate()
                    begin
                        RecurringOnAfterValidate();
                    end;
                }
                field("Recurring Date Interval"; Rec."Recurring Date Interval")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Intervalo de fecha recurrente';
                    Enabled = RecurringDateIntervalEnable;
                    ToolTip = 'Especifica el intervalo de fecha recurrente.';
                }
                field("Calc. Due Date From"; Rec."Calc. Due Date From")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Calcular fecha de vencimiento desde';
                    Enabled = CalcDueDateFromEnable;
                    ToolTip = 'Especifica la fecha desde la que se calculará la fecha de vencimiento.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Finish)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Gardar y cerrar';
                Image = Approve;
                InFooterBar = true;
                ToolTip = 'Finaliza la tarea y la guarda.';
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    FinishPage();
                    CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'Nuevo';

                actionref(Finish_Promoted; Finish)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        EnableFields();
        WizardContactNameOnFormat(Format(Rec."Wizard Contact Name"));
        If Rec.Type = Rec.Type::" " then
            Rec.Type := Rec.Type::"Phone Call";
        case Rec.Type of
            Rec.Type::"Phone Call":
                Tipo := Tipo::Chat;
            Rec.Type::Meeting:
                Tipo := Tipo::Reunion;
        end;
        IsMeeting := (Rec.Type = Rec.Type::Meeting);
    end;

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        AttachmentEnable := true;
        LanguageCodeEnable := true;
        CalcDueDateFromEnable := true;
        RecurringDateIntervalEnable := true;
        WizardContactNameEnable := true;
        AllDayEventEnable := true;
        LocationEnable := true;
        DurationEnable := true;
        EndingTimeEnable := true;
        StartTimeEnable := true;
        SalespersonCodeEnable := true;
        WizardOpportunityDescriptionEd := true;
        WizardCampaignDescriptionEdita := true;
        WizardContactNameEditable := true;
        IsSoftwareAsAService := EnvironmentInfo.IsSaaS();
    end;

    trigger OnOpenPage()
    begin
        IsOnMobile := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone;

        WizardContactNameEditable := false;
        WizardCampaignDescriptionEdita := false;
        WizardOpportunityDescriptionEd := false;

        if Rec."Segment Description" <> '' then
            SegmentDescEditable := false;

        IsMeeting := (Rec.Type = Rec.Type::Meeting);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            FinishPage();
    end;

    var
        Text000: Label '(Multiple)';
        Text001: Label 'sin nombre';
        Cont: Record Contact;
        SalesPurchPerson: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
        Team: Record Team;
        Opp: Record Opportunity;
        SegHeader: Record "Segment Header";
        AttendeeTemp: Record Attendee temporary;
        ClientTypeManagement: Codeunit "Client Type Management";
        SalespersonFilter: Code[20];
        ContactFilter: Code[20];
        WizardContactNameEditable: Boolean;
        WizardCampaignDescriptionEdita: Boolean;
        WizardOpportunityDescriptionEd: Boolean;
        SegmentDescEditable: Boolean;
        IsMeeting: Boolean;
        IsOnMobile: Boolean;
        DurationEnable: Boolean;
        LocationEnable: Boolean;
        AllDayEventEnable: Boolean;
        WizardContactNameEnable: Boolean;
        RecurringDateIntervalEnable: Boolean;
        CalcDueDateFromEnable: Boolean;
        LanguageCodeEnable: Boolean;
        AttachmentEnable: Boolean;
        IsSoftwareAsAService: Boolean;
        Tipo: Option Chat,Reunion;

    protected var
        StartTimeEnable: Boolean;
        EndingTimeEnable: Boolean;
        SalespersonCodeEnable: Boolean;

    procedure Caption(): Text
    var
        CaptionStr: Text;
        Tarea: Record "User Task";
        Id: Integer;
        TId: Text;
    begin
        If Strpos(Rec.GetFilter(Rec.Id_Tabla), 'User Task') <> 0 Then begin
            Tid := CopyStr(Rec.GetFilter(Rec.Id_Tabla), 11);
            if Evaluate(Id, TiD) Then
                If Tarea.Get(Id) then
                    CaptionStr := Tarea.Title;
        End;
        if Cont.Get(Rec.GetFilter(Rec."Contact Company No.")) then
            CaptionStr := CopyStr(Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if Cont.Get(Rec.GetFilter(Rec."Contact No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if SalesPurchPerson.Get(Rec.GetFilter(Rec."Salesperson Code")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + SalesPurchPerson.Code + ' ' + SalesPurchPerson.Name, 1, MaxStrLen(CaptionStr));
        if Team.Get(Rec.GetFilter(Rec."Team Code")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Team.Code + ' ' + Team.Name, 1, MaxStrLen(CaptionStr));
        if Campaign.Get(Rec.GetFilter(Rec."Campaign No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Campaign."No." + ' ' + Campaign.Description, 1, MaxStrLen(CaptionStr));
        if Opp.Get(Rec.GetFilter(Rec."Opportunity No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Opp."No." + ' ' + Opp.Description, 1, MaxStrLen(CaptionStr));
        if SegHeader.Get(Rec.GetFilter(Rec."Segment No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + SegHeader."No." + ' ' + SegHeader.Description, 1, MaxStrLen(CaptionStr));
        if CaptionStr = '' then
            CaptionStr := Text001;

        exit(CaptionStr);
    end;

    local procedure EnableFields()
    begin
        RecurringDateIntervalEnable := Rec.Recurring;
        CalcDueDateFromEnable := Rec.Recurring;

        if not Rec.Recurring then begin
            Evaluate(Rec."Recurring Date Interval", '');
            Clear(Rec."Calc. Due Date From");
        end;

        IsMeeting := Rec.Type = Rec.Type::Meeting;

        if IsMeeting then begin
            StartTimeEnable := not Rec."All Day Event";
            EndingTimeEnable := not Rec."All Day Event";
            DurationEnable := not Rec."All Day Event";
            LocationEnable := true;
            AllDayEventEnable := true;
            LanguageCodeEnable := Rec."Interaction Template Code" <> '';
            AttachmentEnable := Rec."Interaction Template Code" <> '';
        end else begin
            StartTimeEnable := Rec.Type = Rec.Type::"Phone Call";
            EndingTimeEnable := Rec.Type = Rec.Type::"Phone Call";
            DurationEnable := Rec.Type = Rec.Type::"Phone Call";
            LocationEnable := false;
            AllDayEventEnable := false;
        end;

        OnAfterEnableFields(Rec);
    end;

    procedure ValidateTypeField()
    begin
        if Rec.Type <> xRec.Type then
            if Rec.Type = Rec.Type::Meeting then begin
                Rec.ClearDefaultAttendeeInfo();
                Rec.AssignDefaultAttendeeInfo();
                Rec.LoadTempAttachment();
                if not Rec."Team To-do" then
                    if Rec."Salesperson Code" = '' then begin
                        if Cont.Get(Rec."Contact No.") then
                            Rec.Validate("Salesperson Code", Cont."Salesperson Code")
                        else
                            if Cont.Get(Rec."Contact Company No.") then
                                Rec.Validate("Salesperson Code", Cont."Salesperson Code");
                        if Campaign.Get(Rec.GetFilter("Campaign No.")) then
                            Rec.Validate("Salesperson Code", Campaign."Salesperson Code");
                        if Opp.Get(Rec.GetFilter("Opportunity No.")) then
                            Rec.Validate("Salesperson Code", Opp."Salesperson Code");
                        if SegHeader.Get(Rec.GetFilter("Segment No.")) then
                            Rec.Validate("Salesperson Code", SegHeader."Salesperson Code");
                        Rec.Modify();
                    end;
                Rec.GetAttendee(AttendeeTemp);
                CurrPage.AttendeeSubform.PAGE.SetAttendee(AttendeeTemp);
                CurrPage.AttendeeSubform.PAGE.SetTaskFilter(SalespersonFilter, ContactFilter);
                CurrPage.AttendeeSubform.PAGE.UpdateForm();
            end else begin
                Rec.ClearDefaultAttendeeInfo();
                CurrPage.AttendeeSubform.PAGE.GetAttendee(AttendeeTemp);
                Rec.SetAttendee(AttendeeTemp);
                SalespersonCodeEnable := not Rec."Team To-do";
                WizardContactNameEnable := true;
            end;
        IsMeeting := (Rec.Type = Rec.Type::Meeting);
        TypeOnAfterValidate();
        CurrPage.Update();
    end;

    local procedure TypeOnAfterValidate()
    begin
        EnableFields();
    end;

    local procedure AllDayEventOnAfterValidate()
    begin
        EnableFields();
    end;

    local procedure RecurringOnAfterValidate()
    begin
        EnableFields();
    end;

    local procedure InteractionTemplateCodeOnAfter()
    begin
        EnableFields();
    end;

    local procedure WizardContactNameOnFormat(Text: Text[1024])
    begin
        if SegHeader.Get(Rec.GetFilter("Segment No.")) then
            Text := Text000;
    end;

    local procedure FinishPage()
    begin
        CurrPage.AttendeeSubform.PAGE.GetAttendee(AttendeeTemp);
        Rec.SetAttendee(AttendeeTemp);

        Rec.CheckStatus();
        Rec.FinishWizard(false);
        OnAfterFinishPage(Rec);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterEnableFields(var Task: Record "To-do")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFinishPage(var Task: Record "To-do")
    begin
    end;
}

