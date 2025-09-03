package com.smartcity.housecontrol.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    @Value("${smartcity.messaging.queues.house-commands}")
    private String houseCommandQueue;

    @Bean
    public Queue commandQueue() {
        return new Queue(houseCommandQueue, true);
    }
}
