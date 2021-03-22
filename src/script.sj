var sObject = {
  account: 'Account',
  lead: 'Lead',
  contact: 'Contact',
  opportunity: 'Opportunity'
  };

var AccountFields = [
    "Name", 
    "Type",
    "ParentId",
    "Phone",
    "Fax",
    "AccountNumber",
    "Website",
    "Sic",
    "Industry",
    "AnnualRevenue",
    "NumberOfEmployees",
    "Ownership",
    "TickerSymbol",
    "Description",
    "Rating",
    "Site"
    ];

var LeadFields = [
    "LastName",
    "FirstName",
    "Salutation",
    "Title",
    "Company",
    "Street",
    "City",
    "State",
    "PostalCode",
    "Country",
    "Phone",
    "MobilePhone",
    "Fax",
    "Email",
    "Website",
    "Description",
    "LeadSource",
    "Industry",
    "Rating",
    "AnnualRevenue",
    "NumberOfEmployees"
    ];

var ContactFields = [
    "AccountId",
    "LastName",
    "FirstName",
    "Salutation",
    "Phone",
    "Fax",
    "MobilePhone",
    "HomePhone",
    "OtherPhone",
    "AssistantPhone",
    "ReportsToId",
    "Email",
    "Title",
    "Department",
    "AssistantName",
    "LeadSource",
    "Birthdate",
    "Description"
    ];

var OpportunityFields = [
    "AccountId",  
    "Name",
    "Description",
    "StageName",
    "Amount",
    "TotalOpportunityQuantity",
    "CloseDate",
    "Type",
    "NextStep",
    "LeadSource",
    "CampaignId",
    "ContactId"
    ];

function IsDesignTime()
{
  if (typeof Log === "undefined")
    return true;
    
  if (typeof Log.ErrCount === "unknown")
    return true;
    
  return false;
}

function GetPredefinedFields(objectName)
{
  if (objectName === undefined)
    return [];
    
  switch (objectName.toLowerCase())
  {
    case sObject.account.toLowerCase():
      return AccountFields;
    case sObject.lead.toLowerCase():
      return LeadFields;
    case sObject.contact.toLowerCase():
      return ContactFields;
    case sObject.opportunity.toLowerCase():
      return OpportunityFields;
    default:
      return [];
  }
}

function InitializeFields(obj, fieldNames)
{
  // Declare undefined properties to make them visible in Code Completion,
  // but do not convert them to JSON until declared
  for (var i = 0; i < fieldNames.length; ++i)
    obj[fieldNames[i]] = undefined;  
}

function InitializeCallMethod(obj)
{
  // DelphiScript and VBScript do not work correctly with public class functions that have no parameters 
  if (Syntax.CurrentLanguage != "VBScript" && Syntax.CurrentLanguage != "DelphiScript")
    return;
    
  // Implement CallMethod("Count") for these languages
  obj.CallMethod = function(methodName)
  {
    return obj[methodName]();
  }
}

function CopyFields(sourceObj, destObj, fieldNames)
{
  if ((sourceObj == null) || (sourceObj == ""))
    return;
    
  // Copy only specific fields if assigned
  if (fieldNames !== undefined)
  {
    for (var i = 0; i < fieldNames.length; ++i)
      destObj[fieldNames[i]] = sourceObj[fieldNames[i]]; 
      
    return; 
  }
  
  // Copy all fields otherwise
  var sourceFields = aqObject.GetFields(sourceObj);
  var currentField = null;
  while (sourceFields.HasNext())
  {
    currentField = sourceFields.Next();
    try
    {
      destObj[currentField.Name] = currentField.Value;
    }
    catch(ex)
    {
      // do nothing
    }
  }  
}

function ArrayWrapper(arrItems)
{
  var _arrItems = arrItems;
  InitializeCallMethod(this);
  
  function IsValidArray()
  {
    if (_arrItems == null)
      return false; 
      
    if (_arrItems === undefined)
      return false;    

    if (_arrItems.length === undefined)
      return false;   
      
    return true; 
  }
  
  this.Count = function()
  {
    if (IsDesignTime())
      return 0; // Avoid issues with Code Completion
      
    return IsValidArray() ? _arrItems.length : 0;
  }
  
  this.GetItem = function(index)
  {
    if (IsDesignTime())
      return ""; // Avoid issues with Code Completion
      
    if (! IsValidArray())
      return null;
      
    if (aqObject.GetVarType(index) != aqObject.varInteger)
    {
      Log.Error("The index parameter must be a valid zero-based index of an element in the array.");
      return null;
    }
      
    if ((index < 0) || (index >= _arrItems.length))
    {
      Log.Error("The index is out of bounds: " + index + ". The total number of items: " + _arrItems.length);
      return null;
    }
    
    return _arrItems[index];
  }
}

function SalesForceObject(objectName, id, sourceObject)
{
  var _objectName = objectName;
  var _id = id || "";
  var _sourceObject = sourceObject || null; 
  var _metadata = "";
  var _updateableFields = "";
  
  InitializeCallMethod(this);
  
  this.GetId = function()
  {
    return _id;
  }
  
  this.SetCustomField = function(fieldName, fieldValue)
  {
    if (IsDesignTime()) // Check if a test is running or not (to avoid issues with Code Completion)
      return; 
      
    if (fieldName == null || fieldValue == null)
    {
      Log.Error("Please specify both fieldName and fieldValue parameters.");
      return;
    }
      
    this[fieldName] = fieldValue;
  }
  
  this.Send = function(synchronizeOnCreate)
  {
    if (IsDesignTime()) // Check if a test is running or not (to avoid issues with Code Completion)
      return; 
      
    if (_id == "")
    {
      _id = gSalesForce.CreateRecord(_objectName, JSON.stringify(this)); 
      
      // Immediately retrieve the server instance after the creation / update
      if ((_id != "") && (synchronizeOnCreate !== false))
      {
        _sourceObject = gSalesForce.GetRecord(_objectName, _id);  
        CopyFields(_sourceObject, this);
      } 
    }    
    else
    {
      // Initialize metadata for this object's fields
      if (_metadata == "")
        _metadata = gSalesForce.GetMetadata(_objectName);
      
      // Try to update all fields in the object if you failed to get metadata
      if (_metadata == "")
      {
        gSalesForce.UpdateRecord(_objectName, _id, JSON.stringify(this));
        return;
      }
      
      // Initialize the list of updateable fields
      if (_updateableFields == "")
      {
        _updateableFields = new Array(); 
        for (var i = 0; i < _metadata.fields.length; ++i)
        {
          if (_metadata.fields[i].updateable)
            _updateableFields.push(_metadata.fields[i].name);
        }
      } 
      
      // Convert only updateable fields to JSON
      var updateableCopy = new Object();
      CopyFields(this, updateableCopy, _updateableFields);
    
      gSalesForce.UpdateRecord(_objectName, _id, JSON.stringify(updateableCopy));
    }
  }
  
  this.Delete = function()
  {
    if (IsDesignTime()) // Check if a test is running or not (to avoid issues with Code Completion)
      return;

    if (_id == "")
    {
      Log.Warning("Cannot delete this " + _objectName + " object because it has not been added to Salesforce yet.");
      return;
    }

    gSalesForce.DeleteRecord(_objectName, _id);
  }
  
  this.Exists = function()
  {
    if (IsDesignTime()) // Check if a test is running or not (to avoid issues with Code Completion)
      return false;

    if (_id == "")
      return false;
  
    return gSalesForce.RecordExists(_objectName, _id);
  }
  
  InitializeFields(this, GetPredefinedFields(_objectName));
  
  if (IsDesignTime()) // Avoid issues with Code Completion
    return;
    
  CopyFields(_sourceObject, this);
}

function SalesForceObjectAPI(objectName)
{
  if ((objectName == null) && (! IsDesignTime()))
    Log.Error("Please specify a valid Salesforce object name. It must be a string value like Account, Lead, etc.");
    
  var _objectName = aqConvert.VarToStr(objectName); // A valid string must be used
  
  InitializeCallMethod(this);
  
  this.New = function()
  {
    return new SalesForceObject(_objectName);
  }
  
  this.Get = function(id)
  {
    if (IsDesignTime()) // Check if a test is running or not (to avoid issues with Code Completion)
      return new SalesForceObject(_objectName);
  
    var sfObject = gSalesForce.GetRecord(_objectName, id);
    return new SalesForceObject(_objectName, id, sfObject);
  }
  
  this.GetIDs = function()
  {
    if (IsDesignTime()) // Check if a test is running or not (to avoid issues with Code Completion)
      return new ArrayWrapper([]);

    return gSalesForce.FindAllRecords(_objectName);
  }
  
  this.GetFieldNames = function()
  {
    if (IsDesignTime()) // Check if a test is running or not (to avoid issues with Code Completion)
      return new ArrayWrapper([]);

    var metadata = gSalesForce.GetMetadata(_objectName);
    if (metadata == "")
      return new ArrayWrapper([]);
      
    var createableFields = new Array(); 
    for (var i = 0; i < metadata.fields.length; ++i)
    {
      if (metadata.fields[i].createable)
        createableFields.push(metadata.fields[i].name);
    }  
    
    return new ArrayWrapper(createableFields);      
  }
}

function SalesForceAPI()
{
  var _apiVersion = "v50.0";             // Supported API version
  var _apiUrl = "/services/data/v50.0";  // API endpoint URL
  var _accessToken = "";
  var _orgInstance = "";
  
  // apis
  var _recordAPI = "%s/sobjects/%s/";
  var _queryAPI = "%s/query?q=%s";
  
  function CreateRequest(method, url)
  {
    try
    {
      return aqHttp.CreateRequest(method, url);
    }
    catch(exception)
    {
      Log.Error("An exception occurred when trying to create a " + method + " request to " + url, exception.message);
      return null;
    }
  }
  
  function SendRequest(request, body)
  {
    // On runtime only
    if (IsDesignTime())
      return "";
      
    var response = ""; 
    
    Log.LockEvents();     
    try
    {         
      response = body ? request.Send(body) : request.Send();
    }
    catch (ex)
    {
      Log.Error("An exception occurred: " + ex.message, ex.description);
    }
    finally
    {
      Log.UnlockEvents();
    }
    
    return response;
  }
  
  function CheckResponse(response, errorMsg)
  {
    // On runtime only
    if (IsDesignTime())
      return true;
      
    // Consider all 2xx and 3xx status codes correct
    if (response.StatusCode < 400)
      return true;
      
    // Print response data to the Test Log otherwise
    Log.Error(errorMsg,
      "Status Code: " + response.StatusCode + 
      "\r\nStatus Text: " + response.StatusText + 
      "\r\n\r\nHeaders:\r\n" + response.AllHeaders + 
      "\r\n\r\nBody:\r\n" + response.Text);
      
    return false;
  }
  
  function CreateSession(body)
  {
    if (_orgInstance === "")
    {
      Log.Warning("Please specify your organization instance before logging in.", "The organization instance must be in the https://yourInstance.salesforce.com format.");
      return;
    }

    var request = CreateRequest("POST", "https://login.salesforce.com/services/oauth2/token");
    if (request == null)
      return;
      
    request.SetHeader("Content-Type", "application/x-www-form-urlencoded");
  
    var response = SendRequest(request, body);
    if (! CheckResponse(response, "Failed to log in to Salesforce."))
    {
      _accessToken = "";
      return;
    }
  
    _accessToken = JSON.parse(response.Text).access_token;
  }
  
  function Decrypted(value)
  {
    if (value == null)
      return value;
      
    return value.DecryptedValue || value; 
  }
  
  this.LoginWithSessionId = function(clientId, clientSecret, userName, password, token)
  {
    try
    {
      var body = aqString.Format("grant_type=password&client_id=%s&client_secret=%s&username=%s&password=%s", Decrypted(clientId), Decrypted(clientSecret), Decrypted(userName), Decrypted(password) + Decrypted(token));
    }
    catch(exception)
    {
      Log.Error("One or several parameters are not provided or have an incorrect format.", 
        "Please specify:\r\n" + 
        "clientId, clientSecret - Client (Customer) ID and Client (Customer) Secret of your Salesforce Connected Application correspondingly.\r\n" + 
        "userName, password, token - Your username, password, and security token correspondingly.");
        
      return;
    }
    
    CreateSession(body);
  }
  
  this.SetAccessToken = function(accessToken)
  {
    _accessToken = Decrypted(accessToken);
  }
  
  this.GetOrgInstance = function()
  {
    return _orgInstance;
  }
  
  this.SetOrgInstance = function(orgInstance)
  {
    _orgInstance = orgInstance;
  }
  
  function CheckAccessToken()
  {
    if (_orgInstance === "")
    {
      Log.Warning("Please specify your organization instance before logging in.", "The organization instance must be in the https://yourInstance.salesforce.com format.");
      return false;
    }

    if (this._accessToken === "")
    {
      Log.Warning("The access token was not retrieved. Please authenticate.");
      return false;
    }
    
    return true;
  }
  
  function CheckRecordId(recordId)
  {
    // Empty record ID cause call to parent api
    if (recordId == null || recordId == "")
    {
      Log.Error("Please specify a valid record ID - it must be a non-empty string.");
      return false;
    }
    
    return true;
  }

  /////////////////////////////////////////////////////
  ////////////// Create, Update, Delete ///////////////
  /////////////////////////////////////////////////////
  
  this.CreateRecord = function(objectName, jsonData)
  {
    if (! CheckAccessToken())
      return "";
      
    // API call for Account record is /services/data/v50.0/sobjects/Account/
    var request = CreateRequest("POST", _orgInstance + aqString.Format(_recordAPI, _apiUrl, objectName));
    if (request == null)
      return "";
      
    request.SetHeader("Authorization", "Bearer " + _accessToken);
    request.SetHeader("Content-Type", "application/json");
  
    var response = SendRequest(request, jsonData);
    if (! CheckResponse(response, "Failed to create a new record of " + objectName + " type at " + _orgInstance))
    {
      return "";
    }
  
    var result = JSON.parse(response.Text);
    Log.Message("A new " + objectName + " record is successfully created with ID " + result.id, response.Text);
     
    return result.id; 
  }
  
  this.GetMetadata = function(objectName)
  {
    if (! CheckAccessToken())
      return "";
      
    // API call for Account record is /services/data/v50.0/sobjects/Account/describe/
    var request = CreateRequest("GET", _orgInstance + aqString.Format(_recordAPI, _apiUrl, objectName) + "describe/");
    if (request == null)
      return "";
      
    request.SetHeader("Authorization", "Bearer " + _accessToken);
    request.SetHeader("Content-Type", "application/json");
  
    var response = SendRequest(request);
    if (! CheckResponse(response, "Failed to retrieve fields metadata for " + objectName + " at " + _orgInstance))
      return "";
   
    return JSON.parse(response.Text);
  }
  
  this.GetRecord = function(objectName, recordId)
  {
    if (! CheckAccessToken())
      return "";
      
    if (! CheckRecordId(recordId))
      return "";

    // API call for Account record is /services/data/v50.0/sobjects/Account/{ID}
    var request = CreateRequest("GET", _orgInstance + aqString.Format(_recordAPI, _apiUrl, objectName) + recordId);
    if (request == null)
      return;
      
    request.SetHeader("Authorization", "Bearer " + _accessToken);
    request.SetHeader("Content-Type", "application/json");
  
    var response = SendRequest(request);
    if (! CheckResponse(response, "Failed to retrieve a record of " + objectName + " type with ID " + recordId + " at " + _orgInstance))
      return "";
    
    return JSON.parse(response.Text);
  }
  
  this.UpdateRecord = function(objectName, recordId, jsonData)
  {
    if (! CheckAccessToken())
      return;

    // API call for Account record is /services/data/v50.0/sobjects/Account/{ID}
    var request = CreateRequest("PATCH", _orgInstance + aqString.Format(_recordAPI, _apiUrl, objectName) + recordId);
    if (request == null)
      return;
      
    request.SetHeader("Authorization", "Bearer " + _accessToken);
    request.SetHeader("Content-Type", "application/json");
  
    var response = SendRequest(request, jsonData);
    if (CheckResponse(response, "Failed to update the record of " + objectName + " type with ID " + recordId + " at " + _orgInstance))
      Log.Message("The " + objectName + " record with ID " + recordId + " was successfully updated.");
  }

  this.DeleteRecord = function(objectName, recordId)
  {
    if (! CheckAccessToken())
      return;

    // API call for Account record is /services/data/v50.0/sobjects/Account/{ID}
    var request = CreateRequest("DELETE", _orgInstance + aqString.Format(_recordAPI, _apiUrl, objectName) + recordId);
    if (request == null)
      return;
      
    request.SetHeader("Authorization", "Bearer " + _accessToken);
  
    var response = SendRequest(request);
    if (CheckResponse(response, "Failed to delete the record of " + objectName + " type with ID " + recordId + " at " + _orgInstance))
      Log.Message("The " + objectName + " record with ID " + recordId + " was successfully deleted.");
  }
  
  /////////////////////////////////////////////////////
  ///////////////// Query APIs ////////////////////////
  /////////////////////////////////////////////////////
  
  this.Query = function(queryString)
  {
    if (! CheckAccessToken())
      return new ArrayWrapper([]);

    // API call for Account record is /services/data/v50.0/query?q=SELECT+Name+from+Account
    var request = CreateRequest("GET", _orgInstance + aqString.Format(_queryAPI, _apiUrl, queryString));
    if (request == null)
      return new ArrayWrapper([]);
      
    request.SetHeader("X-PrettyPrint", "1");
    request.SetHeader("Authorization", "Bearer " + _accessToken);
  
    var response = SendRequest(request);
    if (! CheckResponse(response, "Failed to execute the following query: " + queryString))
      return new ArrayWrapper([]);
    
    var result = JSON.parse(response.Text);
    var records = new Array();
    for (var i = 0; i < result.records.length; ++i)
      records.push(result.records[i]);    
    
    return new ArrayWrapper(records);
  }
  
  this.FindAllRecords = function(objectName)
  {
    var records = this.Query("SELECT+Id+from+" + objectName);
      
    var ids = new Array();
    for (var i = 0; i < records.Count(); ++i)
      ids.push(records.GetItem(i).Id);
    
    return new ArrayWrapper(ids);
  }
  
  this.RecordExists = function(objectName, id)
  {
    var allRecords = this.FindAllRecords(objectName);
    for (var i = 0; i < allRecords.Count(); ++i)
      if (allRecords.GetItem(i) == id)
        return true;
        
    return false;
  }
}

var gSalesForce = new SalesForceAPI();

function RuntimeObject_LoginWithSessionId(clientId, clientSecret, userName, password, token)
{
  if (IsDesignTime()) // Check if a test is running or not (to avoid issues with Code Completion)
    return;
  
  gSalesForce.LoginWithSessionId(clientId, clientSecret, userName, password, token);
}

function RuntimeObject_SetAccessToken(accessToken)
{
  gSalesForce.SetAccessToken(accessToken);
}

function RuntimeObject_Query(queryString)
{
  if (IsDesignTime()) // Check if a test is running or not (to avoid issues with Code Completion)
    return new ArrayWrapper([]);
  
  return gSalesForce.Query(queryString);  
}

function RuntimeObject_GetOrgInstance()
{
  return gSalesForce.GetOrgInstance();
}

function RuntimeObject_SetOrgInstance(orgInstance)
{
  gSalesForce.SetOrgInstance(orgInstance);
}

function RuntimeObject_GetAccountAPI()
{
  return new SalesForceObjectAPI(sObject.account);
}

function RuntimeObject_GetLeadAPI()
{
  return new SalesForceObjectAPI(sObject.lead);
}

function RuntimeObject_GetContactAPI()
{
  return new SalesForceObjectAPI(sObject.contact);
}

function RuntimeObject_GetOpportunityAPI()
{
  return new SalesForceObjectAPI(sObject.opportunity);
}

function RuntimeObject_GetObjectAPI(objectName)
{
  return new SalesForceObjectAPI(objectName);
}

function Initialize()
{
  // Clear the organization data and access token before usage
  gSalesForce.SetOrgInstance("");
  gSalesForce.SetAccessToken("");
}

function Finalize()
{
  // Clear the organization data and access token after usage
  gSalesForce.SetOrgInstance("");
  gSalesForce.SetAccessToken("");
}