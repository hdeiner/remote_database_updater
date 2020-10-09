package com.deinersoft.zipster;

import com.bettercloud.vault.Vault;
import com.bettercloud.vault.VaultConfig;
import com.bettercloud.vault.VaultException;
import org.json.JSONObject;
import org.apache.commons.lang3.exception.ExceptionUtils;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.TimeZone;

public class Zipster {

    private String zipcode;
    private String radius;
    private final String METERS_TO_MILES = "0.000621371192";

    public Zipster(String zipcode, String radius) throws ZipsterException {
        this.zipcode = zipcode;
        this.radius = radius;
    }

    public JSONObject getPostOfficesWithinRadius() throws ZipsterException  {

        JSONObject resultSet = new JSONObject();
        try {
            resultSet.put("radius", radius);
            resultSet.put("zipcode", zipcode);

            System.out.println("VAULT_ADDRESS=" + System.getenv("VAULT_ADDRESS"));
            System.out.println("VAULT_TOKEN=" + System.getenv("VAULT_TOKEN"));
            System.out.println("ENVIRONMENT=" + System.getenv("ENVIRONMENT"));

            String dbURL = "jdbc:mysql://mysql_container:3306/zipster?useSSL=false";
            String dbUSER = "root";
            String dbPASSWORD = "password";

            try {
                final VaultConfig config = new VaultConfig().address(System.getenv("VAULT_ADDRESS")).token(System.getenv("VAULT_TOKEN")).build();
                final Vault vault = new Vault(config);
                final String vault_path = "ENVIRONMENTS/" + System.getenv("ENVIRONMENT") + "/MYSQL";
                System.out.println("vault_path=" + vault_path);
                dbUSER = vault.logical().read(vault_path).getData().get("user");
                System.out.println("dbUSER=" + dbUSER);
                dbPASSWORD = vault.logical().read(vault_path).getData().get("password");
                System.out.println("dbPASSWORD=" + dbPASSWORD);
                String address = vault.logical().read(vault_path).getData().get("address");
                String port = vault.logical().read(vault_path).getData().get("port");
                dbURL = "jdbc:mysql://" + address + ":" + port + "/zipster?useSSL=false";
                System.out.println("dbURL=" + dbURL);
            } catch (VaultException e) {
                resultSet.put("Exception Root Cause",ExceptionUtils.getRootCause(e).getMessage());
                resultSet.put("Exception StackTrace",ExceptionUtils.getStackTrace(e));
                return resultSet;
            }

            try {
                TimeZone timeZone = TimeZone.getTimeZone("America/New_York");
                TimeZone.setDefault(timeZone);
                Class.forName("com.mysql.cj.jdbc.Driver").newInstance();
                Connection conn = DriverManager.getConnection(dbURL, dbUSER, dbPASSWORD);
                Statement stmt = conn.createStatement();
                ResultSet rs;

                String query =
                        "SELECT T1.*, st_distance_sphere(point(T1.LONGITUDE, T1.LATITUDE), T2.COORDS) * " + METERS_TO_MILES + " AS DISTANCE\n" +
                                "FROM zipster.ZIPCODES AS T1, zipster.ZIPCODES AS T2 \n" +
                                "WHERE st_distance_sphere(point(T1.LONGITUDE, T1.LATITUDE), T2.COORDS) <= " + radius + " / " + METERS_TO_MILES + "\n" +
                                "AND T2.ZIPCODE = " + zipcode + "\n" +
                                "AND T1.ZIPCODE != " + zipcode + "\n" +
                                "ORDER BY st_distance_sphere(point(T1.LONGITUDE, T1.LATITUDE), T2.COORDS) * " + METERS_TO_MILES + " ASC\n";
                System.out.println("query=" + query);

                rs = stmt.executeQuery(query);
                while (rs.next()) {
                    JSONObject row = new JSONObject();
                    row.put("zipcode", rs.getString("ZIPCODE"));
                    row.put("zipcode_type", rs.getString("ZIPCODE_TYPE"));
                    row.put("city", rs.getString("CITY"));
                    row.put("state", rs.getString("STATE"));
                    row.put("location_type", rs.getString("LOCATION_TYPE"));
                    row.put("latitude", rs.getString("LATITUDE"));
                    row.put("longitude", rs.getString("LONGITUDE"));
                    row.put("location", rs.getString("LOCATION"));
                    row.put("decomissioned", rs.getString("DECOMISSIONED"));
                    row.put("distance", rs.getString("DISTANCE"));
                    System.out.println("row=" + row);
                    resultSet.append("results", row);
                }
                conn.close();
            } catch (Exception e) {
                resultSet.put("Exception Root Cause",ExceptionUtils.getRootCause(e).getMessage());
                resultSet.put("Exception StackTrace",ExceptionUtils.getStackTrace(e));
                return resultSet;
            }
        }
        catch (Exception e) {
            resultSet.put("Exception Root Cause",ExceptionUtils.getRootCause(e).getMessage());
            resultSet.put("Exception StackTrace",ExceptionUtils.getStackTrace(e));
            return resultSet;
        }

        return resultSet;

    }
}