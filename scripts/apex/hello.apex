// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

string tempvar = 'Enter_your_name_here';
System.debug('Hello World!');
System.debug('My name is ' + tempvar);

String queryParameters = '{"ticketnumber": "T-1313","contact": "John Doe"}';
HttpResponse response = HttpService.call('POST', 'https://4ad62dd6-87ae-4539-b816-37d93bf67d75.mock.pstmn.io/ticket', queryParameters);
System.debug('response-->>  ' + response.getBody()); 