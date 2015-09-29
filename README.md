# BarcodeScanner_Sharma
Scanning the BarCode for books and getting book information from the web.

This demo project has been created by Abhishek Sharma for the ScanBuy organisation for their review.

#Features

#1.Home screen  

    Button to scan
    
    Button to Show Saved Book Details
    
    Table to show the list of books saved
    
#2.Scanning Screen

    It automatically detects the bar code when it is visible properly in the view(Native Scanner Used).
  
    Cancel Button- If user changes the mind, not to scan and go back.
  
    On detection alert view displayed which navigates to Book Info Page.
  
#3.Book Info Detail Page
    
    User can Add Info
    
    User can Edit Info (In case it is already saved it will update the data)
    
    User can Save Info (Stores data into the database. .sqlite file enclosed in the project)
    
#4.Search The Web for Book Info

    One Touch Search Web Feature
    
    User can search the web(Google Books API search engine) to look for book details using the Bar Code Scanned.
    
    If Book details are found on the Google Books API then the details will be automatically be filled in the Book Info Detail Page. 
    
    If not, then alert is displayed that the book is not found.
    
    
    
Note: 

      Validations used in the text area so that user cannot add text in the No-Of-Pages section in Book Detail Page etc.
      
      Error Handling used in API calls for error detection.
      
      Developed using Xcode-7
      
      Tested in iPhone5, iPhone5s, iPhone6 with ios versions 9.0.1 & 8.1
    
    
    

