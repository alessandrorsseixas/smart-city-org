package br.com.smartcity.housecontrol.domain;

import lombok.Data;
import org.springframework.hateoas.RepresentationModel;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import java.util.List;

@Data
@Entity
public class House extends RepresentationModel<House> {
    @Id
    private String id;
    private String name;

    @OneToMany
    private List<Device> devices;
}
