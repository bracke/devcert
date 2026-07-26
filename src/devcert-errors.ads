package Devcert.Errors is
   type Error_Kind is
     (None,
      Usage,
      CA_State,
      Certificate_Request,
      Cryptographic,
      Trust_Store,
      Permission,
      Unsupported,
      Localization,
      Internal);
end Devcert.Errors;
