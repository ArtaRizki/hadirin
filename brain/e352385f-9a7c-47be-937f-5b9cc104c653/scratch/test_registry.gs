function testRegistry() {
  const MASTER_REGISTRY_ID = "1hTh660vp0AbPn8D37Yg7XE-5HBRDXYA2xSJErORfZ3w";
  try {
    var rows = SpreadsheetApp.openById(MASTER_REGISTRY_ID)
      .getSheetByName("Klien")
      .getDataRange()
      .getValues();
    console.log("Registry rows found:", rows.length);
    for (var i = 1; i < rows.length; i++) {
      console.log("Client:", rows[i][0], "Name:", rows[i][1]);
    }
  } catch (e) {
    console.error("Registry access failed:", e.toString());
  }
}
