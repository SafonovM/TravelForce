public class HttpService {
    public static final String GET_METHOD = 'GET';
    public static final String POST_METHOD = 'POST';

    /**
     * Method to set params.
     *
     * @author Maxim Safonov <bhudzhang@gmail.com>
     *
     * @param  params map of parameters of http call
     * @return string of parameters to set on request
     */
    private static String setParams(Map<String, String> params) {
        List<String> paramsList = new List<String>();
        for (String param : params.keySet()) {
            string value = params.get(param);
            paramsList.add(
                param +
                '=' +
                (value != null ? EncodingUtil.URLENCODE(params.get(param), 'UTF-8') : '')
            );
        }
        return String.join(paramsList, '&');
    }

    /**
     * Method to get endpoint.
     *
     * @author Maxim Safonov <bhudzhang@gmail.com>
     *
     * @param endpoint  named credentials
     * @param  urlParams parameters of http call
     * @return endpoint with or without parameters
     */
    private static String getEndpoint(String endpoint, String urlParams) {
        if (urlParams != null) {
            Map<String, String> urlParamsMap = (Map<String, String>) JSON.deserialize(
                urlParams,
                Map<String, String>.class
            );
            endpoint = endpoint + '?' + setParams(urlParamsMap);
        } 

        return endpoint;
    }

    /**
     * Method to create http request.
     *
     * @author Maxim Safonov <bhudzhang@gmail.com>
     *
     * @param method  http method type
     * @param urlValue endpoint url
     * @param  queryParameters parameters of http call
     * @return httpResponse response with result
     */
    public static HttpResponse call(
        String method,
        String urlValue,
        String queryParameters
    ) {
        HttpResponse response = new HttpResponse();
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setTimeout(120000);
            request.setMethod(method);
            if (method == GET_METHOD) {
                String endPoint = getEndpoint(urlValue, queryParameters);
                request.setEndpoint(endPoint);
            } else if (method == POST_METHOD) {
                request.setHeader('Content-Type', 'application/json');
                request.setHeader('Accept', 'application/json');
                request.setBody(queryParameters);
                String endPoint = getEndpoint(urlValue, null);
                request.setEndpoint(endPoint);
            }

            response = http.send(request);
            return response;
        } catch (System.Exception Ex) {
           System.debug('Exception raised' + Ex);
        }
        return null;
    }
}