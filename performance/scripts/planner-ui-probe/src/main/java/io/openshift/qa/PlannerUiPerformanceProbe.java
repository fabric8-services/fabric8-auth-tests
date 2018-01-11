package io.openshift.qa;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;

import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Login OSIO users and open Planner page
 *
 * @author Pavel Macík <mailto:pavel.macik@gmail.com>
 */
public class PlannerUiPerformanceProbe {
   private static final Logger log = Logger.getLogger("planner-ui-probe");

   static {
      System.setProperty("java.util.logging.SimpleFormatter.format", "%1$tY-%1$tm-%1$td %1$tH:%1$tM:%1$tS.%1$tL %4$-7s [%3$s] %5$s %6$s%n");
   }

   private enum Metric {
      OpenLoginPage("open-login-page"),
      Login("login"),
      LoadPlanner("load-planner"),
      UserMenu("user-menu"),
      Logout("logout");

      private final String logName;

      Metric(final String logName) {
         this.logName = logName;
      }

      String logName() {
         return this.logName;
      }
   }

   private static long start = -1;

   private static final long TIMEOUT = 300;

   public static void main(String[] args) {
      HashMap<Metric, LinkedList<Long>> metricMap = new HashMap<>();
      for (Metric m : Metric.values()) {
         metricMap.put(m, new LinkedList<>());
      }
      String usersProperties = System.getenv("USERS_PROPERTIES");
      if (usersProperties == null) {
         log.info("Set USERS_PROPERTIES environment variable...");
         System.exit(1);
      }
      final String[] users = usersProperties.split("[\n\r]+");
      final int count = Integer.valueOf(System.getProperty("iterations", "1"));
      log.info("Running each user " + count + " times.");
      for (int i = 0; i < count; i++) {
         for (String user : users) {
            final String[] creds = user.split("=");
            final String uName = creds[0];
            final String uPassword = creds[1];
            ChromeOptions op = new ChromeOptions();
            List<String> arguments = new LinkedList<>();
            arguments.add("headless");
            arguments.add("--window-size=1280,960");
            op.addArguments(arguments);
            ChromeDriver driver = new ChromeDriver(op);
            String startUrl = System.getProperty("server.host") + ":" + System.getProperty("server.port");
            log.log(Level.FINE, "Logging user " + uName + " in...");
            _start();
            driver.get(startUrl);
            waitAndClick(driver, "LOG IN");
            final long openLoginPage = _stop();
            log.info(uName + "-" + Metric.OpenLoginPage.logName() + ":" + openLoginPage + "ms");
            driver.findElement(By.id("username")).sendKeys(uName);
            WebElement pass = driver.findElement(By.id("password"));
            pass.sendKeys(uPassword);
            _start();
            pass.submit();
            new WebDriverWait(driver, TIMEOUT).until(ExpectedConditions.urlContains("_home"));
            final long login = _stop();
            log.info(uName + "-" + Metric.Login.logName() + ":" + login + "ms");
            _start();
            driver.get(System.getProperty("server.host") + ":" + System.getProperty("server.port") + System.getProperty("planner.space") + "/plan");
            new WebDriverWait(driver, TIMEOUT).until(ExpectedConditions.elementToBeClickable(By.cssSelector(".f8-wi-list-wrap")));
            final long loadPlanner = _stop();
            log.info(uName + "-" + Metric.LoadPlanner.logName() + ":" + loadPlanner + "ms");
            _start();
            new WebDriverWait(driver, TIMEOUT).until(ExpectedConditions.elementToBeClickable(By.cssSelector(".user-dropdown__username")));
            driver.findElement(By.cssSelector(".user-dropdown__username")).click();
            waitAndClick(driver, "Log Out");
            final long userMenu = _stop();
            log.info(uName + "-" + Metric.UserMenu.logName() + ":" + userMenu + "ms");
            _start();
            new WebDriverWait(driver, TIMEOUT).until(ExpectedConditions.elementToBeClickable(By.id("registerContent")));
            final long logout = _stop();
            log.info(uName + "-" + "logout" + ":" + logout + "ms");
            metricMap.get(Metric.OpenLoginPage).add(openLoginPage);
            metricMap.get(Metric.Login).add(login);
            metricMap.get(Metric.UserMenu).add(userMenu);
            metricMap.get(Metric.LoadPlanner).add(loadPlanner);
            metricMap.get(Metric.Logout).add(logout);
         }
      }
      log.info("All users done.");
      for (Metric metric : Metric.values()) {
         LinkedList<Long> list = metricMap.get(metric);
         Collections.sort(list);
         int size = list.size();
         log.info(metric.logName() + "-time-stats:count=" + size + ";min=" + list.getFirst() + ";med=" + list.get(size / 2) + ";max=" + list.getLast());
      }
      System.exit(0);
   }

   private static void _start() {
      start = System.currentTimeMillis();
   }

   private static long _stop() {
      return System.currentTimeMillis() - start;
   }

   private static void waitAndClick(WebDriver driver, String linkText) {
      new WebDriverWait(driver, TIMEOUT).until(ExpectedConditions.elementToBeClickable(By.partialLinkText(linkText)));
      driver.findElement(By.partialLinkText(linkText)).click();
   }
}

