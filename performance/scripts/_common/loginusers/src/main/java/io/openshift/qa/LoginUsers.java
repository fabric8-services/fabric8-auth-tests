package io.openshift.qa;

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
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Login OSIO users
 *
 * @author Pavel Macík <mailto:pavel.macik@gmail.com>
 */
public class LoginUsers {
   private static final Logger log = Logger.getLogger("login-users-log");

   static {
      System.setProperty("java.util.logging.SimpleFormatter.format", "%1$tY-%1$tm-%1$td %1$tH:%1$tM:%1$tS.%1$tL %4$-7s [%3$s] %5$s %6$s%n");
   }

   private enum Metric {
      OpenLoginPage("open-login-page"),
      Login("login");

      private final String logName;

      Metric(final String logName) {
         this.logName = logName;
      }

      String logName() {
         return this.logName;
      }
   }

   private static long start = -1;

   private static final long TIMEOUT = 60;

   public static void main(String[] args) throws Exception {
      HashMap<Metric, LinkedList<Long>> metricMap = new HashMap<>();
      for (Metric m : Metric.values()) {
         metricMap.put(m, new LinkedList<>());
      }
      final StringBuffer tokens = new StringBuffer();

      Properties usersProperties = new Properties();

      usersProperties.load(new InputStreamReader(LoginUsers.class.getResourceAsStream("/users.properties")));
      for (Map.Entry<Object, Object> user : usersProperties.entrySet()) {
         final String uName = user.getKey().toString();
         final String uPassword = user.getValue().toString();
         final ChromeOptions op = new ChromeOptions();
         final List<String> arguments = new LinkedList<>();
         arguments.add("headless");
         arguments.add("--window-size=1280,960");
         op.addArguments(arguments);
         final WebDriver driver = new ChromeDriver(op);
         final String startUrl = System.getProperty("auth.server.address") + "/api/login?redirect=http%3A%2F%2Flocalhost%3A8090%2Flink.html";
         log.log(Level.FINE, "Logging user " + uName + " in...");
         _start();
         driver.get(startUrl);
         new WebDriverWait(driver, TIMEOUT).until(ExpectedConditions.elementToBeClickable(By.id("kc-login")));
         final long openLoginPage = _stop();
         log.info(uName + "-" + Metric.OpenLoginPage.logName() + ":" + openLoginPage + "ms");
         driver.findElement(By.id("username")).sendKeys(uName);
         final WebElement pass = driver.findElement(By.id("password"));
         pass.sendKeys(uPassword);
         _start();
         pass.submit();
         (new WebDriverWait(driver, TIMEOUT)).until(ExpectedConditions.urlContains("access_token"));
         final long login = _stop();
         log.info(uName + "-" + Metric.Login.logName() + ":" + login + "ms");
         String tokenJson = null;
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
            if (!p.startsWith("token_json=")) {
               continue;
            } else {
               tokenJson = p.split("=")[1];
            }
         }
         final JSONObject json = new JSONObject(tokenJson);
         synchronized (tokens) {
            tokens.append(json.getString("access_token"))
                  .append(";")
                  .append(json.getString("refresh_token"))
                  .append("\n");
         }
         metricMap.get(Metric.OpenLoginPage).add(openLoginPage);
         metricMap.get(Metric.Login).add(login);
      }

      log.info("All users done.");
      for (Metric metric : Metric.values()) {
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
