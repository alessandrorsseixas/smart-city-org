package br.com.smartcity.housecontrol.adapter.out.persistence;

import br.com.smartcity.housecontrol.application.port.out.HouseStatePortOut;
import br.com.smartcity.housecontrol.domain.House;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class JpaHouseStateAdapter implements HouseStatePortOut {

    private final HouseRepository houseRepository;

    @Override
    public List<House> findAll() {
        return houseRepository.findAll();
    }

    @Override
    public Optional<House> findById(String houseId) {
        return houseRepository.findById(houseId);
    }

    @Override
    public void save(House house) {
        houseRepository.save(house);
    }
}
