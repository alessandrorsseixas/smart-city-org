package smart.city.org.eletric.control.config;


import org.springframework.amqp.core.*;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    public static final String QUEUE_NAME = "energySource.notification";
    public static final String EXCHANGE_NAME = "energySource.topic";

    // Nome das filas e exchanges
    public static final String DEAD_LETTER_QUEUE = "deadLetterQueue";
    public static final String DEAD_LETTER_EXCHANGE = "deadLetterExchange";

    @Bean
    public Queue myQueue() {
        return new Queue(QUEUE_NAME, false);
    }

    /*@Bean
    public Queue mainQueue() {
        return QueueBuilder.durable(QUEUE_NAME)
                .withArgument("x-dead-letter-exchange", DEAD_LETTER_EXCHANGE) // Exchange da DLQ
                .withArgument("x-dead-letter-routing-key", "dlq-routing-key") // Routing key da DLQ
                .build();
    }*/

    @Bean
    public TopicExchange myExchange() {
        return new TopicExchange(EXCHANGE_NAME);
    }

    @Bean
    public Binding binding(Queue queue, TopicExchange exchange) {
        return BindingBuilder.bind(queue).to(exchange).with("routing.key.#");
    }
}
