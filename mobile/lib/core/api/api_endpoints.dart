class ApiEndpoints {
  ApiEndpoints._();

  static const token = '/token';
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';
  static const forgotPassword = '/auth/forgot-password';
  static const changePassword = '/auth/change-password';

  static const menus = '/menus';
  static const setup = '/setup';
  static const geography = '/geography';
  static const executivesHierarchy = '/executives/me/hierarchy';
  static const downHierarchy = '/executives/down-hierarchy';

  static const customers = '/customers';
  static const customerMasterData = '/customers/master-data';
  static const customerSearchCities = '/customers/search-cities';
  static const customerSearch = '/customers/search';
  static const bookSellers = '/customers/book-sellers';

  static const contacts = '/contacts';

  static const attendanceCheckIn = '/attendance/check-in';
  static const attendanceCheckOut = '/attendance/check-out';
  static const attendanceToday = '/attendance/today';
  static const attendanceLocations = '/attendance/locations';

  static const plans = '/plans';

  static const dsrEntry = '/visits/dsr-entry';
  static const followUpExecutives = '/visits/follow-up-executives';
  static const visitBackdateRequests = '/visits/backdate-requests';
  static const visits = '/visits';
  static const visitDetails = '/visits/details';

  static const seriesClassLevels = '/catalog/series-class-levels';
  static const titles = '/catalog/titles';
  static const titleSearch = '/catalog/titles/search';
  static const shipmentModes = '/catalog/shipment-modes';

  static String eProductsByBrand(Object brandId) => '/e-products/brands/$brandId/products';
  static String eProductDetails(Object eProductId) => '/e-products/$eProductId/details';

  static const samplingDetails = '/sampling/details';
  static const samplingShipTo = '/sampling/ship-to';
  static const samplingCustomer = '/sampling/customer';
  static const samplingRequests = '/sampling/requests';
  static const samplingApprovals = '/sampling/approvals';

  static const selfStockMasterData = '/self-stock/master-data';
  static const selfStockTradeAddresses = '/self-stock/trade-addresses';
  static const selfStockRequests = '/self-stock/requests';
  static const selfStockApprovals = '/self-stock/approvals';

  static const approvals = '/approvals';
  static const approvalBulkAction = '/approvals/bulk-action';
  static const approvalRoles = '/admin/executives/approval-roles';
  static String approvalRole(Object executiveId) => '/admin/executives/$executiveId/approval-role';

  static const notifications = '/notifications';
  static const filesUpload = '/files/upload';
}
