package smart_city_org.api_gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

@SpringBootApplication
@EnableConfigurationProperties(ApiGatewayApplication.UriConfiguration.class)
@RestController
public class ApiGatewayApplication {

	public static void main(String[] args) {
		SpringApplication.run(ApiGatewayApplication.class, args);
	}


	@Bean
	public RouteLocator myRoutes(RouteLocatorBuilder builder, UriConfiguration uriConfiguration) {
		String httpUri = uriConfiguration.getHttpbin();
		return builder.routes()
				.route(p -> p
						.path("/get")
						.filters(f -> f.addRequestHeader("Hello", "World"))
						.uri(httpUri))
				.route(p -> p
						.host("*.circuitbreaker.com")
						.filters(f -> f
								.circuitBreaker(config -> config
										.setName("mycmd")
										.setFallbackUri("forward:/fallback")))
						.uri(httpUri))
				.build();
	}

	@RequestMapping("/fallback")
	public Mono<String> fallback() {
		return Mono.just("fallback");
	}

	@ConfigurationProperties
	class UriConfiguration {

		private String httpbin = "http://httpbin.org:80";

		public String getHttpbin() {
			return httpbin;
		}

		public void setHttpbin(String httpbin) {
			this.httpbin = httpbin;
		}
	}
}
