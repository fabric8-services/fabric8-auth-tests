package io.openshift.qa;

import org.apache.http.Header;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.json.JSONObject;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.io.File;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLDecoder;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Login OSIO users
 *
 * @author Pavel Macík <mailto:pavel.macik@gmail.com>
 */
public class LoginUsersOauth2 {
   private static final Logger log = Logger.getLogger("login-users-log");

   static {
      System.setProperty("java.util.logging.SimpleFormatter.format", "%1$tY-%1$tm-%1$td %1$tH:%1$tM:%1$tS.%1$tL %4$-7s [%3$s] %5$s %6$s%n");
   }

   private enum MetricAuth {
      OpenLoginPage("open-login-page"),
      GetCode("get-code"),
      GetToken("get-token"),
      Login("login");

      private final String logName;

      MetricAuth(final String logName) {
         this.logName = logName;
      }

      String logName() {
         return this.logName;
      }
   }

   private static long start = -1;

   private static final long TIMEOUT = 60;

   public static void main(String[] args) throws Exception {
      HashMap<MetricAuth, LinkedList<Long>> metricMap = new HashMap<>();
      for (MetricAuth m : MetricAuth.values()) {
         metricMap.put(m, new LinkedList<>());
      }
      final StringBuffer tokens = new StringBuffer();

      Properties usersProperties = new Properties();

      final String baseUrl = System.getProperty("auth.server.address");
      final String clientId = System.getProperty("auth.client.id", "740650a2-9c44-4db5-b067-a3d1b2cd2d01");
      final String redirectUrl = baseUrl + "/api/status";

      usersProperties.load(new InputStreamReader(LoginUsersOauth2.class.getResourceAsStream("/users.properties")));
      for (Map.Entry<Object, Object> user : usersProperties.entrySet()) {
         final String uName = user.getKey().toString();
         final String uPassword = user.getValue().toString();
         final ChromeOptions op = new ChromeOptions();
         final List<String> arguments = new LinkedList<>();
         arguments.add("headless");
         arguments.add("--window-size=1280,960");
         op.addArguments(arguments);
         final WebDriver driver = new ChromeDriver(op);

         UUID uuid = UUID.randomUUID();
         final String startUrl = baseUrl + "/api/authorize?response_type=code"
            + "&client_id=" + clientId
            + "&scope=user:email"
            + "&redirect_uri=" + redirectUrl
            + "&state=" + uuid.toString();
         log.log(Level.FINE, "Logging user " + uName + " in...");
         _start();
         log.fine(" > GET " + startUrl);
         driver.get(startUrl);
         new WebDriverWait(driver, TIMEOUT).until(ExpectedConditions.elementToBeClickable(By.id("kc-login")));
         final long openLoginPage = _stop();
         log.info(uName + "-" + MetricAuth.OpenLoginPage.logName() + ":" + openLoginPage + "ms");
         driver.findElement(By.id("username")).sendKeys(uName);
         final WebElement pass = driver.findElement(By.id("password"));
         pass.sendKeys(uPassword);
         _start();
         pass.submit();
         (new WebDriverWait(driver, TIMEOUT)).until(ExpectedConditions.urlContains(uuid.toString()));
         String redirectedUrl = driver.getCurrentUrl();
         log.fine(" < " + redirectedUrl);
         final long getCode = _stop();
         log.info(uName + "-" + MetricAuth.GetCode.logName() + ":" + getCode + "ms");
         String code = null, returnState = null;
         String[] queryParams = new String[0];
         try {
            queryParams = new URL(URLDecoder.decode(driver.getCurrentUrl(), "UTF-8")).getQuery().split("&");
         } catch (MalformedURLException e) {
            e.printStackTrace();
         } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
         }
         driver.quit();
         for (String p : queryParams) {
            if (p.startsWith("code=")) {
               code = p.split("=")[1];
            } else if (p.startsWith("state=")) {
               returnState = p.split("=")[1];
               continue;
            }
         }
         if (!uuid.toString().equals(returnState)) {
            throw new Exception("Return state (" + returnState + ") should be equal to the request state (" + uuid.toString() + ")");
         }
         HttpClient http = HttpClients.createDefault();

         HttpPost post = new HttpPost(baseUrl + "/api/token");
         //*/ payload as x-www-form-urlencoded
         post.setHeader("Content-Type", "application/x-www-form-urlencoded");
         final String bodyString = "grant_type=authorization_code"
            + "&client_id=" + clientId
            + "&code=" + code
            + "&redirect_uri=" + redirectUrl;
         /*/ //payload as JSON
         post.setHeader("Content-Type", "application/json");
         final String bodyString = "{\"grant_type\":\"authorization_code\","
            + "\"client_id\":\"" + clientId + "\","
            + "\"code\":\"" + code + "\","
            + "\"redirect_uri\":\"" + redirectUrl + "\"}";
         //*/
         log.fine(" > POST " + post.getURI());
         for (Header h : post.getAllHeaders()) {
            log.fine(" > " + h.getName() + ": " + h.getValue());
         }
         log.fine(" > " + bodyString);
         post.setEntity(new StringEntity(bodyString));
         _start();
         HttpResponse response = http.execute(post);
         String responseString = EntityUtils.toString(response.getEntity(), "UTF-8");
         final long getToken = _stop();
         final JSONObject json = new JSONObject(responseString);
         synchronized (tokens) {
            tokens.append(json.getString("access_token"))
                  .append(";")
                  .append(json.getString("refresh_token"))
                  .append("\n");
         }
         log.info(uName + "-" + MetricAuth.GetToken.logName() + ":" + getToken + "ms");
         final long login = getCode + getToken;
         log.info(uName + "-" + MetricAuth.Login.logName() + ":" + login + "ms");
         log.fine(" < " + response.toString());
         log.fine(" < " + responseString);

         metricMap.get(MetricAuth.OpenLoginPage).add(openLoginPage);
         metricMap.get(MetricAuth.GetCode).add(getCode);
         metricMap.get(MetricAuth.GetToken).add(getToken);
         metricMap.get(MetricAuth.Login).add(login);
      }
      log.info("All users done.");
      for (MetricAuth metric : MetricAuth.values()) {
         final LinkedList<Long> list = metricMap.get(metric);
         Collections.sort(list);
         final int size = list.size();
         log.info(metric.logName() + "-time-stats:count=" + size + ";min=" + list.getFirst() + ";med=" + list.get(size / 2) + ";max=" + list.getLast());
      }
      final FileWriter fw = new FileWriter(new File(System.getProperty("user.tokens.file", "user.tokens")), false);
      fw.append(tokens.toString());
      fw.close();
      System.exit(0);
   }

   private static void _start() {
      start = System.currentTimeMillis();
   }

   private static long _stop() {
      return System.currentTimeMillis() - start;
   }

}
