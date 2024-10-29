package smart.city.org.eletric.control.rabbitmq;

import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import smart.city.org.eletric.control.config.RabbitMQConfig;

@Component
public class MainQueueConsumer {

    @Autowired
    private RabbitTemplate rabbitTemplate;

    @RabbitListener(queues = RabbitMQConfig.QUEUE_NAME)
    public void receiveMessage(String message) {
        try {
            // Tente processar a mensagem
            System.out.println("Mensagem recebida na fila principal: " + message);

            // Simular erro para enviar para a DLQ
            if ("error".equalsIgnoreCase(message)) {
                throw new RuntimeException("Simulando falha no processamento");
            }

            // Processamento da mensagem com sucesso
        } catch (Exception e) {
            // Em caso de erro, a mensagem vai para a Dead Letter Queue
            System.out.println("Erro ao processar mensagem. Enviando para a DLQ.");
            throw e;  // Re-lançar a exceção para que o RabbitMQ mova a mensagem para a DLQ
        }
    }
}
