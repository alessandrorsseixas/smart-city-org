package br.com.smartcity.housecontrol.config;

import org.springframework.amqp.core.Queue;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    @Value("${app.messaging.queues.house-commands:house.commands.q}")
    private String houseCommandQueue;

    @Bean
    public Queue commandQueue() {
        return new Queue(houseCommandQueue, true);
    }
}
