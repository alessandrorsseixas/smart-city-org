package smart.city.org.eletric.control.rabbitmq;

import org.springframework.amqp.rabbit.annotation.RabbitHandler;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import smart.city.org.eletric.control.config.RabbitMQConfig;

@Service
public class MessageProducer {

    private final RabbitTemplate rabbitTemplate;

    @Value(RabbitMQConfig.EXCHANGE_NAME)
    private String exchange;

    @Value(RabbitMQConfig.QUEUE_NAME)
    private String routingKey;

    public MessageProducer(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    @RabbitHandler
    public void sendMessage(String message) {
        rabbitTemplate.convertAndSend(exchange, routingKey, message);
        System.out.println("Mensagem enviada: " + message);
    }
}

