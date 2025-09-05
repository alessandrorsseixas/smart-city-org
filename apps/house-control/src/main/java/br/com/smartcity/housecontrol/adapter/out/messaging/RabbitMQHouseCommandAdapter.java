package br.com.smartcity.housecontrol.adapter.out.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import br.com.smartcity.housecontrol.application.port.out.HouseCommandPortOut;
import br.com.smartcity.housecontrol.domain.DeviceCommand;
import lombok.RequiredArgsConstructor;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class RabbitMQHouseCommandAdapter implements HouseCommandPortOut {

    private final RabbitTemplate rabbitTemplate;
    private final Queue commandQueue;
    private final ObjectMapper objectMapper;

    @Override
    public void sendDeviceCommand(DeviceCommand command) {
        try {
            var payload = objectMapper.writeValueAsString(command);
            rabbitTemplate.convertAndSend(commandQueue.getName(), payload);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to serialize command", e);
        }
    }
}
