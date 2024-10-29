package smart.city.org.eletric.control.rabbitmq;

import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import smart.city.org.eletric.control.config.RabbitMQConfig;

@Component
public class DeadLetterQueueConsumer {

    @Autowired
    private RabbitTemplate rabbitTemplate;

    /*@RabbitListener(queues = RabbitMQConfig.DEAD_LETTER_QUEUE)
    public void receiveDeadLetterMessage(String message) {
        System.out.println("Mensagem recebida na DLQ (retry): " + message);

        // Reenviar para a fila principal após um tempo de espera (exemplo: 5 segundos)
        try {
            Thread.sleep(5000); // Simula uma espera de 5 segundos antes de reprocessar
            System.out.println("Reenviando a mensagem para a fila principal");
            rabbitTemplate.convertAndSend(RabbitMQConfig.EXCHANGE_NAME, "routing-key", message);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }*/
}