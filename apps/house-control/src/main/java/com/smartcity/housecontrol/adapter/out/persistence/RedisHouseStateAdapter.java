package com.smartcity.housecontrol.adapter.out.persistence;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartcity.housecontrol.application.port.out.HouseStatePortOut;
import com.smartcity.housecontrol.domain.House;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class RedisHouseStateAdapter implements HouseStatePortOut {

    private final RedisTemplate<String, String> redisTemplate;
    private final ObjectMapper objectMapper;
    private final String prefix = "house:";

    @Override
    public List<House> findAll() {
        var keys = redisTemplate.keys(prefix + "*");
        if (keys == null) return List.of();
        return keys.stream().map(k -> redisTemplate.opsForValue().get(k))
                .map(this::toHouse).collect(Collectors.toList());
    }

    @Override
    public Optional<House> findById(String houseId) {
        var raw = redisTemplate.opsForValue().get(prefix + houseId);
        if (raw == null) return Optional.empty();
        return Optional.ofNullable(toHouse(raw));
    }

    @Override
    public void save(House house) {
        try {
            var json = objectMapper.writeValueAsString(house);
            redisTemplate.opsForValue().set(prefix + house.getId(), json);
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }
    }

    private House toHouse(String json) {
        try {
            return objectMapper.readValue(json, House.class);
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }
    }
}
