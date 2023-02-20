package com.microsoft.azure.simpletodo;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.servers.Server;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import com.microsoft.applicationinsights.attach.ApplicationInsights;

@SpringBootApplication
@OpenAPIDefinition(servers = { @Server(url = "/") })
public class SimpleTodoApplication {

    public static void main(String[] args) {
        new SpringApplication(SimpleTodoApplication.class).run(args);
    }
}
