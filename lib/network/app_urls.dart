enum Environment { beta, live }

class AppUrls {
  // Toggle environment here
  static Environment _env = Environment.live;

  static void setEnvironment(Environment env) {
    _env = env;
  }

  // sample collection controller (do not change this condition )
  static bool get addBagId => _env == Environment.beta;

  // ASMX Base URLs
  static const String _betaAsmxBase =
      'https://betaomsmobapi.lifenityhealth.com/api/Legacy';
  static const String _liveAsmxBase =
      'https://connect.lifenityhealth.com/Webservices/HBTC_Webservices.asmx';

  // ASMX Base URLs updated search
  static const String _betaAsmxSearchBase =
      'https://betaomsmobapi.lifenityhealth.com/api/Legacy';
  static const String _liveAsmxSearchBase =
      'https://connect.lifenityhealth.com/Webservices/HBTCPateintSearch.asmx';

  // ASHX Base URLs
  static const String _betaAshxBase =
      'https://betaomsmobapi.lifenityhealth.com/api/';
  static const String _liveAshxBase =
      'https://connect.lifenityhealth.com/Webservices/Handler/';

  static String get reportBaseUrl => _env == Environment.beta
      ? 'http://reports.avantecodeworx.co.in/API/patient_record_grid.php'
      : 'https://rptconnect.lifenityhealth.com/API/patient_record_grid.php';

  // Base URL getters
  static String get _asmxBase =>
      _env == Environment.beta ? _betaAsmxBase : _liveAsmxBase;

  static String get _ashxBase =>
      _env == Environment.beta ? _betaAshxBase : _liveAshxBase;

  static String get _asmxSearchBase =>
      _env == Environment.beta ? _betaAsmxSearchBase : _liveAsmxSearchBase;

  // -------------------------
  // API Endpoints (.asmx)
  // -------------------------
  static String get getFacilityList => '$_asmxBase/getFacilityList';

  static String get login => '$_asmxBase/Login';

  static String get verifyLoginOtp => '$_asmxBase/VerifyLoginOtp';

  static String get logout => '$_asmxBase/LogINLogoutUser';

  static String get checkApplicationUpdate => '$_asmxBase/APKDownloader';

  static String forgotPassword = '$_asmxBase/ForgotPassword';

  static String resetPassword = '$_asmxBase/ResetPassword';

  static String changePassword = '$_asmxBase/ChangePassword';

  static String get getTotalMsgAndNotificationCount =>
      '$_asmxBase/GetTotalMSGAndNotificationCountByuseridAndDesignationId';

  static String get getCenterList => '$_asmxBase/getCenterList';

  static String get getIdentityProof => '$_asmxBase/GetIdentityProof';

  static String get getMaritalStatus => '$_asmxBase/GetMARITALSTATUS';

  static String get getDistrictList => '$_asmxBase/getDistrictListAPI';

  static String get getCityList => '$_asmxBase/getCityList';

  static String get getStateList => '$_asmxBase/getStateList';

  static String get checkOpdNumberExists => '$_asmxBase/CheckDuplicateOPDIDNO';

  static String get getDoctorReferenceList => '$_asmxBase/GetRefDoctorName';

  static String get searchExistingPatient =>
      '$_asmxBase/PatientSearchForMobileApp';

  static String get getTestNames =>
      '$_asmxBase/GetTestSeriviceWiseFacilityList_Subcataegory';

  static String get sendOTP => '$_asmxBase/SendandVerifyOTP';

  static String get validateMobile => '$_asmxBase/IsMobNoExcist';

  // Then update these two endpoints:
  static String get saveForm =>
      '$_asmxSearchBase/LabDataInsert_UpdatedForABHANewAndCastMaritalAddedHISLISForCDAC';

  static String get savePatientDetails =>
      '$_asmxSearchBase/Insert_PatientBasicInfo_ForCitizenApp';

  /*  static String get orderInputUrl =>
      '$_asmxBase/InsertPatientwiseServiceTubecountNewForPatOtpVerify';*/

  /*  static String get orderInputUrl =>
      '$_asmxBase/InsertPatientwiseServiceTubecountNewForPatOtpVerify';*/

  static String get orderInputUrl =>
      '$_asmxBase/InsertPatientwiseServiceTubecountNewForPatOtpVerifyFlutter';

  /*  static String get orderInputUrl =>
      '$_asmxBase/InsertPatientwiseServiceTubecountNewForPatOtpVerifyFlutter';*/

  static String get getFacilityData =>
      '$_asmxBase/GetFacilitywisePatientRegistrationCount';

  static String get checkBarcode => '$_asmxBase/CheckDuplicateBarcode';

  static String get insertDoctor => '$_asmxBase/InsertRefDocter';

  static String get testAnalysisUrl =>
      '$_asmxBase/GetTestAnalysisReportDashoardDetails_SubCat';
  static final String pendingPatientUrl =
      '$_asmxBase/PendingPatientDashboard_New';

  static String testTypeUrl = '$_asmxBase/HRMSDashBorad_Labwise';

  static String get getRunnerBoyWork => '$_asmxBase/GetRunnerBoyDailyWork_New';

  static String get getProfileData => '$_asmxBase/GetUserDetailsDecriypt';

  static String get getRegisteredPatientList =>
      '$_asmxBase/GetPhleboRegisteredPatientList';

  static String get updatePatientDetails =>
      '$_asmxBase/UpdatePatientOPDReceipt';

  static String get getFacilityListUserWise =>
      '$_asmxBase/GEtFacilityOnLabcode_UserWise';

  static String get getFacilityWiseDataForPickup =>
      '$_asmxBase/GEtFacilityOnLabcode_UserWise';

  static String get insRunnerBoyDailyWorkVisitedFacility =>
      '$_asmxBase/InsertRunnerBoyDailyWorkVisitedFacility_TubecountJSON';

  static String get insertSampleSubmittedAcceptedStatus =>
      '$_asmxBase/InsertSampleSubmittedAcceptedStatus';

  static String get getResourceVisitData =>
      '$_asmxBase/GetRunnerboyListWithMappedFacilityCount';

  static String get getSampleTemperature => '$_asmxBase/GetSampleTemperature';

  static String get getPassKey => '$_asmxBase/getPasskey';

  static String get sampleRecollectionList =>
      '$_asmxBase/GetPateintDetailsforSampleRecollection';

  static String get sampleRecollectionListUpdated =>
      '$_asmxBase/GetRecollectioDashboard';

  static String get rejectedTestDetails =>
      '$_asmxBase/GetPateintDetailswithServicenameforSampleRecollection';

  static String get rejectionRemark =>
      '$_asmxBase/GetRemarkforSampleRecollectionDeny';

  static String get insertRecollectionUpdate =>
      '$_asmxBase/InsMobileEntryofSampleReCollectionNew';

  static String get sampleRemarkList => '$_asmxBase/GetRemarks';

  static String get getCountsForDc => '$_asmxBase/GetCountsForDC';

  static String get insertSampleRemark => '$_asmxBase/INSERTPatientCountSample';

  static String get zeroSampleCalendar =>
      '$_asmxBase/ZeroSampleCountCalender_New';

  static String get facilitySurvey => '$_asmxBase/GetFacilitySurvey';

  static String get insertFacilityVisit => '$_asmxBase/InsertFacilitySurvey';

  static String get summaryUrl => '$_asmxBase/SUMMARYCOUNT_TodayYesterday_New';

  static String get summaryCountUrl =>
      '$_asmxBase/GetSummaryCountDetails_New_Updated';

  static String get getFacilityCenterNames =>
      '$_asmxBase/GetCenterFacilityName';

  static String get getFacilityCenterTypes => '$_asmxBase/GetCenterName';

  static String get getFacilityTypes => '$_asmxBase/GetFacilityTypes_Invoice';

  static String get fetchFacilityNamesByWardFType =>
      '$_asmxBase/GetFacilityloadonWardFtype';

  static String get sendReportToWhatsApp => '$_asmxBase/SendReportWithPdf';

  static String get SendConsentMessage_Consent =>
      '$_asmxBase/SendConsentMessage_Consent';

  static String get consentStatus => '$_asmxBase/Getwhatappconsentsattus';

  static String get getPatientTestListWithStatus =>
      '$_asmxBase/GetPatientTestList_withSTatus';

  static String get getHMISPatientTests =>
      '$_asmxBase/GetTestandTreatmentid_HMIS';

  static String get consumptionDashboard => '$_asmxBase/GetConsuptionDashboard';

  static String get projectFinancialYear => '$_asmxBase/GetProjectFinacialYear';

  /* ------------------ DPDP consent  --------------------*/

  static String get sendRegistrationOtpWithDpdpConsent =>
      '$_asmxBase/SendRegistrationOTPWithDPDPConsent';

  static String get getBeneficiaryConsentDetails =>
      '$_asmxBase/GetBeneficiaryConsentDetails';

  /* ------------------ Qr Code Flow Runner-Boy  --------------------*/
  /*------------------ collect empty bag  --------------------*/
  static String get getSampleBagId => '$_asmxBase/GetSampleBagID';

  static String get insertInitiateBagTransaction =>
      '$_asmxBase/InsertInnitiateBagTransaction';

  static String get insertBagTransactionStatus =>
      '$_asmxBase/InsertBagTransactionStatus';

  /*---------------- Hand over to phlebotomist --------------------*/
  static String get getPhlebotomistList =>
      '$_asmxBase/GetPhleboDesgWiseUserlist';

  static String get getScanQRForAndTransactionID =>
      '$_asmxBase/GetScanQRForAndTransactionID';

  /*------------------- Hand over to Connector----------------------*/

  static String get updateBagTransactionStatus =>
      '$_asmxBase/UpdateInnitiateBagTransaction';

  /*------------------- Collected Bags for Submission ----------------------*/

  static String get collectedBagsForLabSubmission =>
      '$_asmxBase/GetClosedSampleBagList_forLabSubmission';

  /*-------------------- Phlebotomist Accept Bags ----------------------*/

  static String get assignedBagsForPhlebotomist =>
      '$_asmxBase/GetGetPhleboAssignBagList';

  static String get getBagStatusTracking => '$_asmxBase/GetBagStatusNew';

  /*static String get getBagStatusTracking => '$_asmxBase/GetBagStatus';*/

  static String get getScanbagInfo => '$_asmxBase/GetScanbagInfo';

  static String get getTubeTranferToOtherLab =>
      '$_asmxBase/GetTubeTranferToOtherLab';

  /*----------------- Invoice Tracking ------------------------------*/
  static String get getYearDropDown => '$_asmxBase/GetYear';

  static String get getBillingMonth => '$_asmxBase/GeBillingMonth';

  static String get facilityWiseInvoiceStatus =>
      '$_asmxBase/GetFacilityWiseInvoiceStatus';

  static String get getInvoiceStages => '$_asmxBase/GetinvoiceStages';

  /*----------------- Sample Live Tracking ------------------------------*/
  static String get getSampleLiveTrackingRb =>
      '$_asmxBase/GetSamplebagTrackingReport_inAppRBConnector';

  static String get getBagDetailsRbTrackingDashboard =>
      '$_asmxBase/GetBagDetails_Rb_trackingDahsboard';

  /*----------------- Eho facility wise summary ------------------------------*/

  static String get facilityTypeSummary =>
      '$_asmxBase/GetEHOAndCES_FacilityCOunt';

  /*------------------ Patient registration Bag qr code flow */

  static String get getBagStatusUsingUserId =>
      '$_asmxBase/GetBagStatus_UseingUserid';

  static String get getBagCountStatus =>
      '$_asmxBase/GetGetSampleBagPatientCount';

  /*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
  /*   REVAMP QR CODE FLOW 19 th feb onwards 🫡🫡🫡🫡                             */
  /*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

  /// phlebotomist login

  static String get getUserwiseQRBagSession =>
      '$_asmxBase/GetUserwiseQRBagSession';

  static String get getQRBagDetails => '$_asmxBase/Proc_GetQRBagDetails';

  static String get insertStartQRCodeBagEvent =>
      '$_asmxBase/InsertStartQRCodeBegEvent';

  static String get insertQRBagSessionEvent =>
      '$_asmxBase/InsertQRBagSession_Event';

  static String get getActiveQRBagSessions =>
      '$_asmxBase/GetActiveQRBagSessions';

  static String get getRegistrationDetailsQRBag =>
      '$_asmxBase/GetRegistrationDetails_QRBag';

  static String get getPatientDetailsForMergingTest =>
      '$_asmxBase/GetPatientDetailsFor_MergingTest';

  static String get mergeSugarBarcode =>
      '$_asmxBase/InsertMergeSugarTest_Barcode';

  /// collect bag from phlebotomist (RB login)

  static String get getQRBagCount => '$_asmxBase/GETQRBagCount';

  static String get getBagStatus => '$_asmxBase/GetBagStatus';

  static String get transferBag => '$_asmxBase/InsertTransferSample_to_QRBag';

  static String getCollectedQRBagDetails =
      '$_asmxBase/GetCollectedQRBagDetails';
  static String submitQRBagToLabOrHandover =
      '$_asmxBase/SubmitQRBagToLabOrHandover';

  //----------------------- Lab technician qr code -----------------------//

  static String getScanQRBag = '$_asmxBase/GETScanQRBag';

  // Step 2 — Fetch detailed bag info for lab team
  static String getBagDetailsForLabTeam =
      '$_asmxBase/Proc_GetQRBagDetails_ForLabTeam';

  // -------------------------
  // Sample Collection
  // -------------------------
  static String getOrdersList = '$_asmxBase/orders/details';
  static String updateOrder = '$_asmxBase/UpdateSampleOrderStatus';

  static String getComplicationsList =
      '$_asmxBase/GetSampleCollectionComplicationDetails';

  static String getIncompleteReasons =
      '$_asmxBase/GetSampleCollectionIncompleteReasonDetails';

  static String getSampleRequirements =
      '$_asmxBase/orders/{orderId}/sample-requirements';

  static String submitSampleCollection =
      '$_asmxBase/orders/{orderId}/collect_InsertSampleCollectionOrder_API';

  static String sendOTPToPatient = '$_asmxBase/send-otp';

  static String verifyPatientOTP = '$_asmxBase/verify-otp';

  static String get locationTracking =>
      '$_asmxBase/UserSampleOrderLocationTracking';

  static String dishaSampleCollectionSync =
      '$_asmxBase/orders/{orderId}/Recolled_DishaSampleCollection_API';

  static String rescheduledSlots = '$_asmxBase/user/available-slots';


  static String appointmentRescheduled = '$_asmxBase/InsertSampleCollAppoinmentReschedule';

  static String appointmentRescheduledReason = '$_asmxBase/GetRescheduleReasone';



  // -------------------------
  // API Endpoints (.ashx)
  // -------------------------
  static String get insRunnerBoyDailyWork =>
      '${_ashxBase}InsertRunnerBoyDailyWork';

  static String get uploadVisitPhoto => '${_ashxBase}Facility_Survey';

  static String get insertFacilityWiseInvoiceStatus =>
      '${_ashxBase}InsertFaciltyWiseInvoiceStatus';

  static String get uploadTrfImage => '${_ashxBase}AddTrfPhoto';

  static String get addConsentPhoto => '${_ashxBase}AddConsentPhoto';
}
