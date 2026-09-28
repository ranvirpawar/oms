enum Environment { beta, live, dev }

class AppUrls {
  // Toggle environment here
  static Environment _env = Environment.live;

  static void setEnvironment(Environment env) {
    _env = env;
  }

  // Base URLs
  static const String _betaBase =
      'https://betaomsmobapi.lifenityhealth.com/api/Legacy';

  static const String _devBase =
      'https://devpcaremobapi.lifenityhealth.com/api/Legacy';
  static const String _liveBase = 'yet-to-deploy';

  // ASMX Base URLs updated search
  static const String _betaSearchBase =
      'https://betaomsmobapi.lifenityhealth.com/api/Legacy';
  static const String _devSearchBase =
      'https://devpcaremobapi.lifenityhealth.com/api/Legacy';
  static const String _liveSearchBase =
      'https://connect.lifenityhealth.com/Webservices/HBTCPateintSearch.asmx';

  // ASHX Base URLs
  static const String _betaHandlerBase =
      'https://betaomsmobapi.lifenityhealth.com/api/';
  static const String _devHandlerBase =
      'https://devpcaremobapi.lifenityhealth.com/api/';
  static const String _liveHandlerBase =
      'https://connect.lifenityhealth.com/Webservices/Handler/';

  // Reports server — dev reuses the staging reports server (no dedicated
  // dev reports endpoint exists yet); only live uses the production one.
  static String get reportBaseUrl => switch (_env) {
    Environment.beta =>
      'http://reports.avantecodeworx.co.in/API/patient_record_grid.php',
    Environment.dev =>
      'http://reports.avantecodeworx.co.in/API/patient_record_grid.php',
    Environment.live =>
      'https://rptconnect.lifenityhealth.com/API/patient_record_grid.php',
  };

  // Base URL getters
  static String get _baseUrl => switch (_env) {
    Environment.beta => _betaBase,
    Environment.dev => _devBase,
    Environment.live => _liveBase,
  };

  static String get _handlerBaseUrl => switch (_env) {
    Environment.beta => _betaHandlerBase,
    Environment.dev => _devHandlerBase,
    Environment.live => _liveHandlerBase,
  };

  static String get _searchBaseUrl => switch (_env) {
    Environment.beta => _betaSearchBase,
    Environment.dev => _devSearchBase,
    Environment.live => _liveSearchBase,
  };

  // -------------------------
  // API Endpoints (.asmx)
  // -------------------------
  static String get getFacilityList => '$_baseUrl/getFacilityList';

  static String get login => '$_baseUrl/Login';

  static String get verifyLoginOtp => '$_baseUrl/VerifyLoginOtp';

  static String get logout => '$_baseUrl/LogINLogoutUser';

  static String get checkApplicationUpdate => '$_baseUrl/APKDownloader';

  static String forgotPassword = '$_baseUrl/ForgotPassword';

  static String resetPassword = '$_baseUrl/ResetPassword';

  static String changePassword = '$_baseUrl/ChangePassword';

  static String get getTotalMsgAndNotificationCount =>
      '$_baseUrl/GetTotalMSGAndNotificationCountByuseridAndDesignationId';

  static String get getCenterList => '$_baseUrl/getCenterList';

  static String get getIdentityProof => '$_baseUrl/GetIdentityProof';

  static String get getMaritalStatus => '$_baseUrl/GetMARITALSTATUS';

  static String get getDistrictList => '$_baseUrl/getDistrictListAPI';

  static String get getCityList => '$_baseUrl/getCityList';

  static String get getStateList => '$_baseUrl/getStateList';

  static String get checkOpdNumberExists => '$_baseUrl/CheckDuplicateOPDIDNO';

  static String get getDoctorReferenceList => '$_baseUrl/GetRefDoctorName';

  static String get searchExistingPatient =>
      '$_baseUrl/PatientSearchForMobileApp';

  static String get getTestNames =>
      '$_baseUrl/GetTestSeriviceWiseFacilityList_Subcataegory';

  static String get sendOTP => '$_baseUrl/SendandVerifyOTP';

  static String get validateMobile => '$_baseUrl/IsMobNoExcist';

  // Then update these two endpoints:
  static String get saveForm =>
      '$_searchBaseUrl/LabDataInsert_UpdatedForABHANewAndCastMaritalAddedHISLISForCDAC';

  static String get savePatientDetails =>
      '$_searchBaseUrl/Insert_PatientBasicInfo_ForCitizenApp';

  /*  static String get orderInputUrl =>
      '$_baseUrl/InsertPatientwiseServiceTubecountNewForPatOtpVerify';*/

  /*  static String get orderInputUrl =>
      '$_baseUrl/InsertPatientwiseServiceTubecountNewForPatOtpVerify';*/

  static String get orderInputUrl =>
      '$_baseUrl/InsertPatientwiseServiceTubecountNewForPatOtpVerifyFlutter';

  /*  static String get orderInputUrl =>
      '$_baseUrl/InsertPatientwiseServiceTubecountNewForPatOtpVerifyFlutter';*/

  static String get getFacilityData =>
      '$_baseUrl/GetFacilitywisePatientRegistrationCount';

  static String get checkBarcode => '$_baseUrl/CheckDuplicateBarcode';

  static String get insertDoctor => '$_baseUrl/InsertRefDocter';

  static String get testAnalysisUrl =>
      '$_baseUrl/GetTestAnalysisReportDashoardDetails_SubCat';
  static final String pendingPatientUrl =
      '$_baseUrl/PendingPatientDashboard_New';

  static String testTypeUrl = '$_baseUrl/HRMSDashBorad_Labwise';

  static String get getRunnerBoyWork => '$_baseUrl/GetRunnerBoyDailyWork_New';

  static String get getProfileData => '$_baseUrl/GetUserDetailsDecriypt';

  static String get sendUserProfileUpdateOtp =>
      '$_baseUrl/SendUserProfileUpdateOTP';

  static String get verifyUserProfileUpdateOtp =>
      '$_baseUrl/VerifyUserProfileUpdateOTP';

  static String get updateUserProfile => '$_baseUrl/UpdateUserProfile';

  static String get getRegisteredPatientList =>
      '$_baseUrl/GetPhleboRegisteredPatientList';

  static String get updatePatientDetails => '$_baseUrl/UpdatePatientOPDReceipt';

  static String get getFacilityListUserWise =>
      '$_baseUrl/GEtFacilityOnLabcode_UserWise';

  static String get getFacilityWiseDataForPickup =>
      '$_baseUrl/GEtFacilityOnLabcode_UserWise';

  static String get insRunnerBoyDailyWorkVisitedFacility =>
      '$_baseUrl/InsertRunnerBoyDailyWorkVisitedFacility_TubecountJSON';

  static String get insertSampleSubmittedAcceptedStatus =>
      '$_baseUrl/InsertSampleSubmittedAcceptedStatus';

  static String get getResourceVisitData =>
      '$_baseUrl/GetRunnerboyListWithMappedFacilityCount';

  static String get getSampleTemperature => '$_baseUrl/GetSampleTemperature';

  static String get getPassKey => '$_baseUrl/getPasskey';

  static String get sampleRecollectionList =>
      '$_baseUrl/GetPateintDetailsforSampleRecollection';

  static String get sampleRecollectionListUpdated =>
      '$_baseUrl/GetRecollectioDashboard';

  static String get rejectedTestDetails =>
      '$_baseUrl/GetPateintDetailswithServicenameforSampleRecollection';

  static String get rejectionRemark =>
      '$_baseUrl/GetRemarkforSampleRecollectionDeny';

  static String get insertRecollectionUpdate =>
      '$_baseUrl/InsMobileEntryofSampleReCollectionNew';

  static String get sampleRemarkList => '$_baseUrl/GetRemarks';

  static String get getCountsForDc => '$_baseUrl/GetCountsForDC';

  static String get insertSampleRemark => '$_baseUrl/INSERTPatientCountSample';

  static String get zeroSampleCalendar =>
      '$_baseUrl/ZeroSampleCountCalender_New';

  static String get facilitySurvey => '$_baseUrl/GetFacilitySurvey';

  static String get insertFacilityVisit => '$_baseUrl/InsertFacilitySurvey';

  static String get summaryUrl => '$_baseUrl/SUMMARYCOUNT_TodayYesterday_New';

  static String get summaryCountUrl =>
      '$_baseUrl/GetSummaryCountDetails_New_Updated';

  static String get getFacilityCenterNames => '$_baseUrl/GetCenterFacilityName';

  static String get getFacilityCenterTypes => '$_baseUrl/GetCenterName';

  static String get getFacilityTypes => '$_baseUrl/GetFacilityTypes_Invoice';

  static String get fetchFacilityNamesByWardFType =>
      '$_baseUrl/GetFacilityloadonWardFtype';

  static String get sendReportToWhatsApp => '$_baseUrl/SendReportWithPdf';

  static String get SendConsentMessage_Consent =>
      '$_baseUrl/SendConsentMessage_Consent';

  static String get consentStatus => '$_baseUrl/Getwhatappconsentsattus';

  static String get getPatientTestListWithStatus =>
      '$_baseUrl/GetPatientTestList_withSTatus';

  static String get getHMISPatientTests =>
      '$_baseUrl/GetTestandTreatmentid_HMIS';

  static String get consumptionDashboard => '$_baseUrl/GetConsuptionDashboard';

  static String get projectFinancialYear => '$_baseUrl/GetProjectFinacialYear';

  /* ------------------ DPDP consent  --------------------*/

  static String get sendRegistrationOtpWithDpdpConsent =>
      '$_baseUrl/SendRegistrationOTPWithDPDPConsent';

  static String get getBeneficiaryConsentDetails =>
      '$_baseUrl/GetBeneficiaryConsentDetails';

  /* ------------------ Qr Code Flow Runner-Boy  --------------------*/
  /*------------------ collect empty bag  --------------------*/
  static String get getSampleBagId => '$_baseUrl/GetSampleBagID';

  static String get insertInitiateBagTransaction =>
      '$_baseUrl/InsertInnitiateBagTransaction';

  static String get insertBagTransactionStatus =>
      '$_baseUrl/InsertBagTransactionStatus';

  /*---------------- Hand over to phlebotomist --------------------*/
  static String get getPhlebotomistList =>
      '$_baseUrl/GetPhleboDesgWiseUserlist';

  static String get getScanQRForAndTransactionID =>
      '$_baseUrl/GetScanQRForAndTransactionID';

  /*------------------- Hand over to Connector----------------------*/

  static String get updateBagTransactionStatus =>
      '$_baseUrl/UpdateInnitiateBagTransaction';

  /*------------------- Collected Bags for Submission ----------------------*/

  static String get collectedBagsForLabSubmission =>
      '$_baseUrl/GetClosedSampleBagList_forLabSubmission';

  /*-------------------- Phlebotomist Accept Bags ----------------------*/

  static String get assignedBagsForPhlebotomist =>
      '$_baseUrl/GetGetPhleboAssignBagList';

  static String get getBagStatusTracking => '$_baseUrl/GetBagStatusNew';

  /*static String get getBagStatusTracking => '$_baseUrl/GetBagStatus';*/

  static String get getScanbagInfo => '$_baseUrl/GetScanbagInfo';

  static String get getTubeTranferToOtherLab =>
      '$_baseUrl/GetTubeTranferToOtherLab';

  /*----------------- Invoice Tracking ------------------------------*/
  static String get getYearDropDown => '$_baseUrl/GetYear';

  static String get getBillingMonth => '$_baseUrl/GeBillingMonth';

  static String get facilityWiseInvoiceStatus =>
      '$_baseUrl/GetFacilityWiseInvoiceStatus';

  static String get getInvoiceStages => '$_baseUrl/GetinvoiceStages';

  /*----------------- Sample Live Tracking ------------------------------*/
  static String get getSampleLiveTrackingRb =>
      '$_baseUrl/GetSamplebagTrackingReport_inAppRBConnector';

  static String get getBagDetailsRbTrackingDashboard =>
      '$_baseUrl/GetBagDetails_Rb_trackingDahsboard';

  /*----------------- Eho facility wise summary ------------------------------*/

  static String get facilityTypeSummary =>
      '$_baseUrl/GetEHOAndCES_FacilityCOunt';

  /*------------------ Patient registration Bag qr code flow */

  static String get getBagStatusUsingUserId =>
      '$_baseUrl/GetBagStatus_UseingUserid';

  static String get getBagCountStatus =>
      '$_baseUrl/GetGetSampleBagPatientCount';

  /*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
  /*   REVAMP QR CODE FLOW 19 th feb onwards 🫡🫡🫡🫡                             */
  /*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

  /// phlebotomist login

  static String get getUserwiseQRBagSession =>
      '$_baseUrl/GetUserwiseQRBagSession';

  static String get getQRBagDetails => '$_baseUrl/Proc_GetQRBagDetails';

  static String get insertStartQRCodeBagEvent =>
      '$_baseUrl/InsertStartQRCodeBegEvent';

  static String get insertQRBagSessionEvent =>
      '$_baseUrl/InsertQRBagSession_Event';

  static String get getActiveQRBagSessions =>
      '$_baseUrl/GetActiveQRBagSessions';

  static String get getRegistrationDetailsQRBag =>
      '$_baseUrl/GetRegistrationDetails_QRBag';

  static String get getPatientDetailsForMergingTest =>
      '$_baseUrl/GetPatientDetailsFor_MergingTest';

  static String get mergeSugarBarcode =>
      '$_baseUrl/InsertMergeSugarTest_Barcode';

  /// collect bag from phlebotomist (RB login)

  static String get getQRBagCount => '$_baseUrl/GETQRBagCount';

  static String get getBagStatus => '$_baseUrl/GetBagStatus';

  static String get transferBag => '$_baseUrl/InsertTransferSample_to_QRBag';

  static String getCollectedQRBagDetails = '$_baseUrl/GetCollectedQRBagDetails';
  static String submitQRBagToLabOrHandover =
      '$_baseUrl/SubmitQRBagToLabOrHandover';

  //----------------------- Lab technician qr code -----------------------//

  static String get getScanQRBag => '$_baseUrl/GETScanQRBag';

  // Step 2 — Fetch detailed bag info for lab team
  static String getBagDetailsForLabTeam =
      '$_baseUrl/Proc_GetQRBagDetails_ForLabTeam';

  // -------------------------
  // Sample Collection
  // -------------------------
  static String getOrdersList = '$_baseUrl/orders/details';
  static String updateOrder = '$_baseUrl/UpdateSampleOrderStatus';

  static String getComplicationsList =
      '$_baseUrl/GetSampleCollectionComplicationDetails';

  static String getIncompleteReasons =
      '$_baseUrl/GetSampleCollectionIncompleteReasonDetails';
  static String getRejectedReason = '$_baseUrl/GetAssignRejectedReason';

  static String getSampleRequirements =
      '$_baseUrl/orders/{orderId}/sample-requirements';

  static String submitSampleCollection =
      '$_baseUrl/orders/{orderId}/collect_InsertSampleCollectionOrder_API';

  static String sendOTPToPatient = '$_baseUrl/send-otp';

  static String verifyPatientOTP = '$_baseUrl/verify-otp';

  static String get locationTracking =>
      '$_baseUrl/UserSampleOrderLocationTracking';

  static String get dishaSampleCollectionSync =>
      '$_baseUrl/orders/Recolled_DishaSampleCollection_API/{orderId}';

  static String get rescheduledSlots => '$_baseUrl/user/available-slots';

  static String get appointmentRescheduled =>
      '$_baseUrl/InsertSampleCollAppoinmentReschedule';

  static String get appointmentRescheduledReason =>
      '$_baseUrl/GetRescheduleReasone';

  static String get sendOtpSampleReschedule =>
      '$_baseUrl/send-otp-SampleReschedule';

  static String get verifyOtpSampleReschedule =>
      '$_baseUrl/verify-otp-SampleReschedule';

  static String get checkBarcodeAvailability =>
      '$_baseUrl/barcode/availability';

  static String get collectionChecklist => '$_baseUrl/collection-checklist';

  static String get insertCollectionCheckList =>
      '$_baseUrl/orders/{order-id}/collection-checklist';

  ///  dashboard

  static String get dashboardCount => '$_baseUrl/phlebo/dashboard-summary';
  static String get checkBagAlreadyAssigned =>'$_baseUrl/phlebo/check-bag-already-assigned';
  // -------------------------
  // API Endpoints (.ashx)
  // -------------------------
  static String get insRunnerBoyDailyWork =>
      '${_handlerBaseUrl}InsertRunnerBoyDailyWork';

  static String get uploadVisitPhoto => '${_handlerBaseUrl}Facility_Survey';

  static String get insertFacilityWiseInvoiceStatus =>
      '${_handlerBaseUrl}InsertFaciltyWiseInvoiceStatus';

  static String get uploadTrfImage => '${_handlerBaseUrl}AddTrfPhoto';

  static String get addConsentPhoto => '${_handlerBaseUrl}AddConsentPhoto';




}
